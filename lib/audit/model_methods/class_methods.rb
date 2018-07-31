module Audit
  module ModelMethods
    module ClassMethods

      def ignore_changes_in_fields
        ["created_at", "updated_at", "_id", "last_modified_by", "last_modified_via", "last_modified_via_value"]
      end

      def get_audit_relations
        self.relations.select{|key, changes| changes[:relation] == Mongoid::Relations::Referenced::ManyToMany || changes[:relation] == Mongoid::Relations::Referenced::In}
      end

    end

  end
end
