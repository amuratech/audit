module Audit
  module Userstamp
    module Store
      def self.store_key key
        "userstamp/#{key.to_s.underscore}".to_sym
      end

      def self.get key
        store[store_key(key)]
      end

      def self.set key, value
        store[store_key(key)] = value
      end

      def self.store
        defined?(RequestStore) ? RequestStore.store : Thread.current
      end
    end
  end
end
