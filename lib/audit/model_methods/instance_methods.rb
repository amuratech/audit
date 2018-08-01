module Audit
  module ModelMethods
    module InstanceMethods

      ## This method prepares a single row to be displayed in audit panel
      #@params [String] denotes what kind of change like create, update, etc
      #@return [Hash] of audit details
      def create_audit_details change_type
        begin
          modified_by = last_modified_by_name

          json = {
            "modified_at": Time.now.to_s,
            "transaction_id": AuditHelper::Store.get("transaction_id"),
            "user_id": self.last_modified_by.to_s,
            "via": self.last_modified_via,
            "via_value": self.last_modified_via_value,
            "user_name": (modified_by.present? ? modified_by : "system"),
            "change_type": change_type
          }

          json.merge! indexed_fields_json

          json.merge!({
            associated_with: associated_with_klasses_json
          })

          json[:audit_entries] = audit_entries_json

          json[:audit_meta] = audit_meta if self.respond_to? "audit_meta"
          if change_type == "destroy" || json[:audit_entries].present?
            unless Rails.env.test?
              if Rails.env.development?
                AuditHelper::Job.perform_now(json.to_json)
              else
                AuditHelper::Job.perform_later(json.to_json)
              end
            end
          end
          json
        rescue => e
          Rails.logger.info "Error in create_audit_details with class #{self.class} doing #{change_type}"
        end
      end

      private

      def audit_fields_changes
        audit_fields = self.class.audit_fields
        self.changes.select do |key, values|
          audit_fields.include?(key)
        end
      end

      ## Related class is a class self belongs to e.g Hierarchy::Node belongs to Hierarchy.  So Hierarchy is a parent class of Hierarchy::Node
      #@return [Array] parent class details
      def associated_with_klasses_json
        associated_with = []
        self.class.audit_metadata[:associated_with].each do |entry|
          parent = self.send(entry.to_s) if self.respond_to?(entry.to_s)
          if parent.present?
            associated_with << {
              parent_class: parent.class.to_s,
              parent_id: parent.id.to_s,
              parent_name: (parent.respond_to?(:name) ? parent.name : "")
            }
          end
        end
        associated_with
      end

      def indexed_fields_json
        self.class.indexed_fields.reduce(Hash.new) do |hash, field|
          hash[field] = self.send(field)
          hash
        end.merge({
          "subject_class": self.class.to_s,
          "subject_id": self.id.to_s,
          "subject_name": (self.respond_to?(:name) ? self.name : "")
        })
      end

      def audit_field_is_association? field
        self.class.get_audit_relations.find{ |name,value| value[:relation].foreign_key(name) == field } || self.class.is_field_reference_id_without_association?(field)
      end

      def audit_field_association_json field, old_value, new_value
        entry = {}

        if self.class.is_field_reference_id_without_association?(field)
          class_type = new_value.present? ? new_value.class.to_s : old_value.class.to_s
          metadata = self.class.audit_reference_id_metadata field
          if class_type == "Array"
            entry[:id_field] = true
            entry[:old_value] = convert_array_to_named_objects(metadata["klass"], old_value)
            entry[:new_value] = convert_array_to_named_objects(metadata["klass"], new_value)
          else
            entry[:id_field] = true
            if metadata.has_key?("method")
              if self.changes.keys.include?(metadata[:dependent_field])
                klass = self.changes[metadata[:dependent_field]][0]
              else
                klass = self.send(metadata[:method]).class
              end
              entry[:old_value] = convert_to_hash_with_names old_value, klass
              new_value_object = self.send(metadata[:method])
            else
              entry[:old_value] = convert_to_hash_with_names old_value, metadata["klass"]
              new_value_object = metadata["klass"].constantize.find new_value if new_value.present?
            end
            entry[:new_value] = new_value_object.present? ? {id: new_value_object.id.to_s, name: new_value_object.try(:name) } : ""
          end
        else
          entry[:old_value] = get_related_models_with_named_hash(field_name, old_value)
          entry[:new_value] = get_related_models_with_named_hash(field_name, new_value)
          entry[:id_field] = true
        end
        entry
      end

      ## This method returns related models that come from enable_audit [:associated_with] in the name, id form
      #@params [String] field_name whose name to be returned
      #@params [Object] id whose name, id hash to be returned
      #@return [Hash] of {id: id, name: name}
      def get_related_models_with_named_hash field_name, id
        audit_relations = self.class.get_audit_relations
        relation = audit_relations.find{|name,value| value[:relation].foreign_key(name) == field_name}
        if relation[1][:relation] == Mongoid::Relations::Referenced::In
          ##TODO if relation changes check for old relation[1][:name]+"_type"
          if relation[1][:polymorphic] == true
            related_class = self.send(relation[1][:name].to_s+"_type").constantize
          else
            related_class = relation[1].klass
          end
        elsif relation[1][:relation] == Mongoid::Relations::Referenced::ManyToMany
          related_class = relation[1].klass
        end
        object_with_name = convert_to_hash_with_names id, related_class
      end

      #@params [Object] id whose name, id hash to be returned
      #@params [String] klass name on which object to be found
      #@return [Hash] of {id: id, name: name}

      def convert_to_hash_with_names id, klass
        object = klass.to_s.constantize.where(id: id.to_s).first if klass
        {id: object.id.to_s, name: (object.respond_to?(:name) ? object.name : "")} if object
      end

      #@params [Array <Object>] ids whose name, id hash to be returned
      #@params [String] klass name on which object to be found
      #@return [Array <Hash>] of {id: id, name: name}

      def convert_array_to_named_objects klass, array_of_objects
        output_array = Array.new
        if array_of_objects.present?
          output_array = array_of_objects.compact.flatten.collect do |object_id|
            convert_to_hash_with_names object_id, klass
          end
        end
        output_array
      end

      def audit_entries_json
        audit_fields_changes.collect do |field_name, changes|
          old_value = changes[0]
          new_value = changes[1]

          class_type = new_value.present? ? new_value.class.to_s : old_value.class.to_s

          entry = {field_name: field_name, data_type: class_type, old_value: "", new_value: ""}

          if audit_field_is_association?(field_name)
            audit_field_association_json field, old_value, new_value
          else
            entry.merge!({ old_value: old_value, new_value: new_value })
          end
        end
      end

      def audit_meta
        json = {}
        # value = self.last_modified_via_value
        # workflow_id, _action_id = value.scan(/workflows\/(\w*)\/actions\/(\w*)/).flatten
        # json[:workflow_name] = Workflow.where(id:workflow_id).first.try(:name)
        json
      end

      def last_modified_by_name
        model = Audit.configuration.track_modified_by_model.constantize

        if self.last_modified_by.present?
          record = model.find(self.last_modified_by)
          record.send(Audit.configuration.track_modified_by_name_field)
        end
      end

    end
  end
end
