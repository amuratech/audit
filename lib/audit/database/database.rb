module Audit
  class Database
    def self.insert json
      audits = ::Mongoid.default_client['audits']
      audit_entries = ::Mongoid.default_client['audit_entries']
      audit_associations = ::Mongoid.default_client['audit_associations']
      hex = SecureRandom.hex
      entries = nil
      audit_meta = nil
      associations = nil

      if !json[:audit_entries].nil?
        entries = json[:audit_entries].collect do |data|
          AuditHelper::JsonHelper.format data
        end
      end
      if !json[:associated_with].nil?
        associations = json[:associated_with].collect do |data|
          AuditHelper::JsonHelper.format data
        end
      end
      if !json[:audit_meta].nil?
        audit_meta = json[:audit_meta].each do |tt|
          AuditHelper::JsonHelper.format json[:audit_meta]
        end
      end
      json.delete :audit_entries
      json.delete :associated_with
      json.delete :audit_meta

      formatted_json = AuditHelper::JsonHelper.format json
      formatted_json.each{|k,v| json[k] = v}

      audits.insert_one(json)

      if !entries.nil?
        audit_entries.insert_many(entries)
      end
      if !audit_meta.nil?
        audit_entries.insert_one(audit_meta)
      end
      if !associations.nil?
        audit_associations.insert_many(associations)
      end

    end
  end
end
