module Audit
  class GoogleCloud
    attr_accessor :query, :datastore
    def initialize
      @gcloud = ::Google::Cloud.new Audit.google_cloud_credentials.cloud_store_project_id, Audit.google_cloud_credentials.gcp_key_file_path
      @datastore = @gcloud.datastore
    end

    def self.create json
      gcloud = self.save(json)
    end

    def build_query params
      @query = @datastore.query.kind("Audit")
      if params[:filters].present?
        params[:filters].each do |_, criteria|
          if ([:key, :value].all?{|s| criteria.key?(s)}) && !criteria.has_value?('') && !criteria.has_value?(nil)
            if criteria["key"] == "modified_at"
              date_range = criteria["value"].split("-")
              start_date = Time.strptime(date_range[0], Audit.options.date_format)
              end_date = Time.strptime(date_range[1], Audit.options.date_format).end_of_day
              @query.where("modified_at", "<=", end_date.to_s)
              @query.where("modified_at", ">=", start_date.to_s)
            else
              @query.where(criteria["key"], "=", criteria["value"])
            end
          end
        end
      end
      @query.order("modified_at", :desc) if ( !params[:filters] || (params[:filters].present? && !params[:filters].values.collect{|criteria| criteria["key"]}.include?("modified_at")))
      if params[:page].present?
        page = params[:page].to_i
        # page = 0 if page < 0
        @query.offset(app_setting.per_page * page)
      end
      @query.limit(app_setting.per_page)
      @query
    end

    def get params
      @query = self.build_query params
      audits = @datastore.run @query
      audits.collect{ |audit| parse_json audit }
    end

    def save json
      hex = SecureRandom.hex
      audit = @datastore.entity "Audit", "#{hex}" do |t|
        t["entries"] = json[:audit_entries].collect do |data|
          @datastore.entity "AuditEntry" do |tt|
            entry_json = AuditHelper::Transaction.format_json data
            entry_json.each{|k,v| tt[k] = v}
            tt
          end
        end
        t["associations"] = json[:associated_with].collect do |data|
          @datastore.entity "Association" do |tt|
            entry_json = AuditHelper::Transaction.format_json data
            entry_json.each{|k,v| tt[k] = v}
            tt
          end
        end
        json.delete :audit_entries
        json.delete :associated_with
        if json[:audit_meta].present?
          t["audit_meta"] = @datastore.entity "AuditEntry" do |tt|
            meta_json = AuditHelper::Transaction.format_json json[:audit_meta]
            meta_json.each{|k,v| tt[k] = v}
            tt
          end
        end
        json.delete :audit_meta
        json = AuditHelper::Transaction.format_json json
        json.each{|k,v| t[k] = v}
        t
      end
      @datastore.save audit unless Rails.env.test?
    end

    private

    def parse_json task
      properties = task.properties
      json = {}
      json["associations"] = []
      if !properties["associations"].empty?
        properties["associations"].each do |assc|
          json["associations"] << {parent_name: assc["parent_name"], parent_id: assc["parent_id"], parent_class: assc["parent_class"], primary: assc["primary"]}
        end
      end
      json.merge!({
                "_id": task.key.name,
                "change_type": properties["change_type"],
                "subject_class": properties["subject_class"],
                "subject_name": properties["subject_name"],
                "user_id": properties["user_id"],
                "user_name": properties["user_name"],
                "via": properties["via"],
                "modified_at": properties["modified_at"]
              })
      json["entries"] ||= []
      properties["entries"].each do |entry|
        json["entries"] << {
                            field_name: entry.properties["field_name"],
                            old_value: entry.properties["old_value"],
                            new_value: entry.properties["new_value"],
                            data_type: entry.properties["data_type"],
                            id_field: entry.properties["id_field"]
                          }
      end
      json
    end
  end
end
