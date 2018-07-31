module AuditHelper
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :action_controller do
      before_action do |_|
        AuditHelper::Store.set("transaction_id", SecureRandom.hex)
      end
    end
  end
end
