# frozen_string_literal: true

module Vario
  # Who may see a topic of a settable and change its settings: everyone,
  # unless the app says otherwise, for all topics (config.topic_policy) or
  # for one (a policy named after it):
  #
  #   class SettingsPolicy < Vario::TopicPolicy
  #     def show?
  #       settable == Current.account
  #     end
  #   end
  #
  #   class ModulesSettingsPolicy < SettingsPolicy
  #     def show?
  #       super && user.super_user?
  #     end
  #   end
  class TopicPolicy
    attr_reader :user, :record

    delegate :settable, :topic, to: :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def show?
      true
    end

    def update?
      show?
    end
  end
end
