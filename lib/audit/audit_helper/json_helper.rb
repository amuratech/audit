# TODO: Vrushali - handle hash is not allowed in Google DataStore
module AuditHelper
  module JsonHelper
    def self.format json, allow_hash=true
      if json.is_a?(Array)
        result = json.collect do |value|
          klass = value.class
          if [Float, Fixnum, TrueClass, FalseClass, Date, DateTime, Time].include?(klass)
            value
          elsif value.is_a?(Array)
            self.format value, false
          elsif value.is_a?(Hash)
            if allow_hash
              self.format value, false
            else
              value.to_json
            end
          else
            begin
              if value.to_s.length > 250
                "changed"
              else
                value.to_s.encode("UTF-8")
              end
            rescue
              # TODO: log error
              ""
            end
          end
        end
        result
      elsif json.is_a?(Hash)
        result = {}
        json.each do |key, value|
          klass = value.class
          if [Float, Fixnum, TrueClass, FalseClass, Date, DateTime, Time].include?(klass)
            result[key.to_s] = value
          elsif value.is_a?(Array)
            result[key.to_s] = self.format value, false
          elsif value.is_a?(Hash)
            result[key.to_s] = value.to_json
          else
            begin
              if value.to_s.length > 250
                result[key.to_s] = "changed"
              else
                result[key.to_s] = value.to_s.encode("UTF-8")
              end
            rescue
              # TODO: log error
              result[key.to_s] = ""
            end
          end
        end
        result
      end
    end
  end
end
