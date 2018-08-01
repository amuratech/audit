module Audit
  module ModelMethods
    module ClassMethods
      def get_audit_relations
        self.relations.select{|key, changes| changes[:relation] == Mongoid::Relations::Referenced::ManyToMany || changes[:relation] == Mongoid::Relations::Referenced::In}
      end

      def audit_metadata
        Audit.configuration.metadata.find{|ele| ele[:klass] == self.to_s}
      end

      def audit_fields
        self.audit_metadata[:audit_fields].map(&:to_s)
      end

      def indexed_fields
        self.audit_metadata[:indexed_fields].map(&:to_s)
      end

      def is_field_reference_id_without_association? field
        self.audit_metadata[:reference_ids_without_associations].include?(field)
      end

      def audit_reference_id_metadata field
        self.audit_metadata[:reference_ids_without_associations].find{|hash| hash[:field] == field}
      end
    end

  end
end
