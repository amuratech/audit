module Audit
  module ModelMethods
    module InstanceMethods

      ## Related class is a class self belongs to e.g Hierarchy::Node belongs to Hierarchy.  So Hierarchy is a parent class of Hierarchy::Node
      #@return [Array] parent class details
      def get_related_klasses_for_audit
        associated_with = []
        Audit.configuration.metadata.select{|ele| ele[:klass] == self.class.to_s && ele[:associated_with]}.each do |klass|
          klass[:associated_with].each do |entry|
            parent = self.send(entry.to_s.downcase) if self.respond_to?(entry.to_s.downcase)
            associated_with << {
              parent_class: (parent.class.to_s if parent),
              parent_id: (parent.id.to_s if parent.respond_to?(:id)) ,
              parent_name: (parent.name if parent.respond_to?(:name)),
              primary: true
              } if parent
            end
        end
        associated_with
      end

      ## It generates a hash of values to be stored in datastore for any change to be audited.
      #@return [Hash] with all changes to be shown in audits
      def audit_json
        json = {}
        json = json.with_indifferent_access
        related_classes = get_related_klasses_for_audit
        json.merge!({
          "modified_at": Time.now.to_s,
          "subject_class": self.class.to_s,
          "subject_id": self.id.to_s,
          "subject_name": self.respond_to?(:name) ? self.name : "",
          "transaction_id": AuditHelper::Store.get("transaction_id"),
          "user_id": self.last_modified_by.to_s,
          "via": self.last_modified_via,
          "via_value": self.last_modified_via_value
        })

        json["user_name"] = "system"
        current_user_id = Audit::Userstamp::Store.get("current_user_id")
        model = Audit.configuration.track_modified_by_model.constantize
        if current_user_id
          if user = model.find(current_user_id)
            json["user_name"] = model.send(Audit.configuration.track_modified_by_name_field)
          end
        end
        json
      end

      def track_create
        create_audit_details "create"
      end

      def track_update
        create_audit_details "update"
      end

      def track_destroy
        create_audit_details "destroy"
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
        object = klass.to_s.constantize.where(id: id.to_s).only(self.class.required_fields).first if klass
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

      ## This method prepares a single row to be displayed in audit panel
      #@params [String] denotes what kind of change like create, update, etc
      #@return [Hash] of audit details
      def create_audit_details change_type
        # begin
          json = {}
          audit_related_key = self.class.get_audit_relations.collect{|key, r| r[:relation].foreign_key(key)}
          json[:change_type] = change_type
          json[:audit_entries] = []
          extras = Audit.configuration.metadata.collect{|hash| hash[:reference_ids_without_associations]}.flatten.compact.uniq
          self.changes.each do |field_name, changes|
            if !self.class.ignore_changes_in_fields.include?(field_name)
              old_value = changes[0]
              new_value = changes[1]
              class_type = new_value.present? ? new_value.class.to_s : old_value.class.to_s
              entry = {field_name: field_name, data_type: class_type, old_value: "", new_value: ""}
              if audit_related_key.include?(field_name)
                entry[:old_value] = get_related_models_with_named_hash(field_name, old_value)
                entry[:new_value] = get_related_models_with_named_hash(field_name, new_value)
                entry[:id_field] = true
              elsif (extra = extras.find{|hash| hash[:name_of_key] == field_name})
                if class_type == "Array"
                  klass = extra["klass"]
                  entry[:id_field] = true
                  entry[:old_value] = convert_array_to_named_objects(klass, old_value)
                  entry[:new_value] = convert_array_to_named_objects(klass, new_value)
                else
                  if extra.has_key?("method")
                    if self.changes.keys.include?(extra[:dependent_field])
                      klass = self.changes[extra[:dependent_field]][0]
                    else
                      klass = self.send(extra[:method]).class
                    end
                    entry[:id_field] = true
                    entry[:old_value] = convert_to_hash_with_names old_value, klass
                    new_value_object = self.send(extra[:method])
                    entry[:new_value] = new_value_object.present? ? {id: new_value_object.id.to_s, name: new_value_object.try(:name) } : ""
                  end
                end
              else
                entry.merge!({ old_value: old_value, new_value: new_value })
              end
              json[:audit_entries] << entry
            end
          end
          json = json.merge self.audit_json
          json[:audit_meta] = self.audit_meta if self.respond_to? "audit_meta"
          if change_type == "destroy" || json[:audit_entries]
            unless Rails.env.test?
              if Rails.env.development?
                AuditHelper::Job.perform_now(json.to_json)
              else
                AuditHelper::Job.perform_later(json.to_json)
              end
            end
          end
          json
        # rescue => e
        #   if Rails.env.production? || Rails.env.staging?
        #     Honeybadger.notify(e, params: json)
        #   else
        #     Rails.logger.info "Error in create_audit_details with class #{self.class} doing #{change_type}"
        #   end
        # end
      end

      def audit_meta
        json = {}
        # value = self.last_modified_via_value
        # workflow_id, _action_id = value.scan(/workflows\/(\w*)\/actions\/(\w*)/).flatten
        # json[:workflow_name] = Workflow.where(id:workflow_id).only(self.class.required_fields).first.try(:name)
        json
      end

      private

      def ensure_last_modified_by
        current_user_id = Userstamp::Store.get("current_user_id")
        if current_user_id.present?
          self.last_modified_by = current_user_id
        end
      end

      def ensure_last_modified_via
        referer = Audit::Userstamp::Store.get("referer")
        if referer.present?
          self.last_modified_via = "api"
          self.last_modified_via_value = referer
        else
          warn "Setting last_modified_via to system for #{self.class} with id #{self.id}" unless Rails.env.test? || Rails.env.development?
          self.last_modified_via = "system"
          self.last_modified_via_value = "system"
        end
      end

    end
  end
end
