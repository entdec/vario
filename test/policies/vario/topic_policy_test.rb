# frozen_string_literal: true

require 'test_helper'

module Vario
  class TopicPolicyTest < ActiveSupport::TestCase
    # The app's policy for all topics, and one topic's own
    setup do
      @account = accounts(:boxture)
      @topic_policy = Vario.config.topic_policy

      settings_policy = Object.const_set(:SettingsPolicy, Class.new(TopicPolicy) do
        def show?
          settable == user[:account]
        end
      end)
      Object.const_set(:PrintNodeSettingsPolicy, Class.new(settings_policy) do
        def update?
          super && user[:admin]
        end
      end)
    end

    teardown do
      Vario.config.topic_policy = @topic_policy
      Object.send(:remove_const, :SettingsPolicy)
      Object.send(:remove_const, :PrintNodeSettingsPolicy)
    end

    def policy(user, topic, settable = @account)
      Pundit.policy!(user, SettableTopic.new(settable: settable, topic: topic))
    end

    test 'everyone may see and change every topic by default' do
      policy = policy(nil, ExamplesSettings)

      assert_instance_of TopicPolicy, policy
      assert policy.show?
      assert policy.update?
      assert_equal [@account, ExamplesSettings], [policy.settable, policy.topic]
    end

    test "the app's policy for all topics" do
      Vario.config.topic_policy = 'SettingsPolicy'

      assert_instance_of SettingsPolicy, policy({ account: @account }, ExamplesSettings)
      assert policy({ account: @account }, ExamplesSettings).update?
      refute policy({ account: accounts(:skepr) }, ExamplesSettings).show?
      refute policy({ account: accounts(:skepr) }, ExamplesSettings).update?
    end

    test "a topic's own policy" do
      assert_instance_of PrintNodeSettingsPolicy, policy({ account: @account }, PrintNodeSettings)
      assert policy({ account: @account }, PrintNodeSettings).show?
      refute policy({ account: @account }, PrintNodeSettings).update?
      assert policy({ account: @account, admin: true }, PrintNodeSettings).update?
    end

    test 'a topic of a settable, by its key and title' do
      topic = SettableTopic.new(settable: @account, topic: PrintNodeSettings)

      assert_equal %w[print_node PrintNode], [topic.key, topic.title]
    end
  end
end
