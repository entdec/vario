# frozen_string_literal: true

module Vario
  # The values of a topic's settings for a settable in a context, by the
  # settings' keys (a boolean's also with a question mark)
  #
  #   reader = account.settings(:shipping, order: order)
  #   reader.cutoff_time        # => "15:00"
  #   reader.partial_shipping?  # => true
  #   reader[:cutoff_time]
  class TopicReader
    def initialize(settable, topic, context = {})
      @settable = settable
      @topic = topic.is_a?(Class) ? topic : Topic.find(settable, topic)
      raise UnknownSetting, "Topic '#{topic}' is not defined for #{settable.class.name}" unless @topic

      @context = context
      @definitions = @topic.definitions.values.index_by(&:key)
    end

    def [](key)
      definition = @definitions.fetch(key.to_s) { raise UnknownSetting, "Setting '#{key}' is not defined in #{@topic.name}" }
      @settable.explain(definition.name, @context).value
    end

    def respond_to_missing?(method, include_private = false)
      @definitions.key?(method.to_s.delete_suffix('?')) || super
    end

    def method_missing(method, *args)
      key = method.to_s.delete_suffix('?')
      return super unless args.empty? && @definitions.key?(key)

      self[key]
    end
  end
end
