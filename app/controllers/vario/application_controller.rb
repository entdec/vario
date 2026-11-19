module Vario
  class ApplicationController < Vario.config.base_controller.constantize
    protect_from_forgery with: :exception

    layout Vario.config.admin_layout

    def add_breadcrumbs(*args)
      method(:add_breadcrumbs).super_method&.call(*args)
    end

    private

    # A topic of a settable's policy (Vario::TopicPolicy)
    def policy(topic)
      Pundit.policy!(vario_user, topic)
    end

    def vario_user
      SettableTopic.user_of(self)
    end
  end
end
