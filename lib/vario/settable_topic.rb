# frozen_string_literal: true

module Vario
  # A topic of a settable: what is shown, changed and authorized (Pundit
  # finds its policy, Vario::TopicPolicy)
  #
  #   authorize Vario::SettableTopic.new(settable: account, topic: ShippingSettings), :update?
  SettableTopic = Data.define(:settable, :topic) do
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
