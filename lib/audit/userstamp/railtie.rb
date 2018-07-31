module Userstamp
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :action_controller do
      before_action do |c|
        if c.current_user.present?
          Audit::Userstamp::Store.set("current_user_id", c.current_user.id)
        end
        Audit::Userstamp::Store.set("referer", c.request.referer)
      end
    end
  end
end
