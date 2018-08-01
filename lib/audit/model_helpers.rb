require_relative "model_methods"

module Mongoid
  module Document
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def enable_audit *args
        options = args.extract_options!
        options = options.with_indifferent_access

        Audit.configuration.metadata << {
          klass: self.to_s,
          track: options[:track] || ["create", "update", "destroy"],
          audit_fields: options[:audit_fields] || [],
          indexed_fields: options[:indexed_fields] || [],
          associated_with: (options[:associated_with].present? ? options[:associated_with].uniq : []),
          reference_ids_without_associations: (options[:reference_ids_without_associations].present? ? options[:reference_ids_without_associations].uniq : [])
        }

        self.include Audit::ModelMethods
      end

      def audits_enabled?
        Audit.configuration.metadata.select{|x| x[:klass] == self.to_s }.present?
      end

    end
  end
end
