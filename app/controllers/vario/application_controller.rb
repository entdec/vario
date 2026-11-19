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

    # The host's Pundit user, else its current user
    def vario_user
      return pundit_user if respond_to?(:pundit_user, true)

      current_user if respond_to?(:current_user, true)
    end
  end
end
