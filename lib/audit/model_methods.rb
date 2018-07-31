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
	end
end
