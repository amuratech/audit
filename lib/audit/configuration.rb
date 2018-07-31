module Audit
  class Configuration
    attr_accessor :metadata, :store, :track_modified_by, :track_modified_by_model, :track_modified_by_name_field, :date_format, :date_format, :cloud_store_project_id, :cloud_store_project_id

    def initialize
      @metadata = []
      @store = 'database',
      @track_modified_by = false,
      @track_modified_by_model = 'User',
      @track_modified_by_name_field = 'name',
      @date_format = "%d/%m/%y",
      @date_time_format = "%d/%m/%Y %H:%M"
      @cloud_store_project_id = nil
      @gcp_key_file_path = nil
    end
  end
end
