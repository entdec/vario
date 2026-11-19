# frozen_string_literal: true

module Vario
  # A topic of a settable: what is shown, changed and authorized (Pundit
  # finds its policy, Vario::TopicPolicy)
  #
  #   authorize Vario::SettableTopic.new(settable: account, topic: ShippingSettings), :update?
  SettableTopic = Data.define(:settable, :topic) do
    # The settable's topics the user may see (show?), for the pages and the
    # host's menu (vario_menu_items)
    def self.visible(settable, user)
      Topic.for(settable).map { |topic| new(settable: settable, topic: topic) }.select { |topic| Pundit.policy!(user, topic).show? }
    end

    # The user a controller authorizes: the host's Pundit user, else its
    # current user
    def self.user_of(controller)
      return controller.send(:pundit_user) if controller.respond_to?(:pundit_user, true)

      controller.send(:current_user) if controller.respond_to?(:current_user, true)
    end

    # The topic's own policy (ShippingSettingsPolicy), else the app's for all
    # topics (config.topic_policy)
    def policy_class
      "#{topic.name}Policy".safe_constantize || Vario.config.topic_policy.constantize
    end

    def key
      topic.key
    end

    def title
      topic.title
    end
  end
end
