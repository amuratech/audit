require_relative "model_methods/class_methods"
require_relative "model_methods/instance_methods"

module Audit
	module ModelMethods
		def self.included(base)
			base.extend Audit::ModelMethods::ClassMethods
			base.field :last_modified_by, type: BSON::ObjectId unless base.respond_to?(:last_modified_by)
			base.field :last_modified_via, type: String unless base.respond_to?(:last_modified_via)
			base.field :last_modified_via_value, type: String unless base.respond_to?(:last_modified_via_value)
			options = Audit.configuration.metadata.select{ |x| x[:klass] == base.to_s }.first
			base.after_create :track_create if options[:track].blank? || options[:track].include?("create")
			base.after_update :track_update if options[:track].blank? || options[:track].include?("update")
			base.after_destroy :track_destroy if options[:track].blank? || options[:track].include?("destroy")
			base.before_save :ensure_last_modified_by, :ensure_last_modified_via
			base.include Audit::ModelMethods::InstanceMethods
		end

		private

		def track_create
      create_audit_details "create"
    end

    def track_update
      create_audit_details "update"
    end

    def track_destroy
      create_audit_details "destroy"
    end

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
