module AuditHelper
  class Job < ActiveJob::Base
    def perform json
      json = JSON.parse(json)
      json = json.with_indifferent_access
      # throw "Audit meta cannot be blank" if json[:audit_meta].blank?
      if Audit.configuration.store == "google_cloud"
        Audit::GoogleCloud.create json
      else
        Audit::Database.insert json
      end
    end
  end
end
