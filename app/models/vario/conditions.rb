# frozen_string_literal: true

module Vario
  # When a refinement applies: "if [all] of the following conditions are met:
  # [location] [is] [Rotterdam]". A rule's variable is a path in the context
  # a setting is read with (order.business_model), compared with Mensa's
  # operators. Ported from Nuntius::Conditions, with the same format and the
  # same cases (test/fixtures/files/conditions_cases.json, from flow forms).
  #
  # Stored as {"match" => "all" | "any", "rules" => [{"variable", "operator",
  # "value", "value_to"}]}, value_to only for between.
  #
  # A variable that is a record or a drop (location, order.customer) is its
  # id, so a rule on it stores the id; without it, <variable>_id counts, so
  # setting(..., location_id: id) meets a rule on location too.
  class Conditions
    MATCHES = %w[all any].freeze
    OPERATORS = %w[is isnt matches does_not_match gt gteq lt lteq between is_empty isnt_empty].freeze
    WITHOUT_VALUE = %w[is_empty isnt_empty].freeze
    TRUE_VALUES = %w[true yes ja 1 y j].freeze

    Rule = Data.define(:variable, :operator, :value, :value_to)

    attr_reader :match, :rules

    # data: the stored hash, or the form's (rules may be numbered)
    def initialize(data = {})
      data = data.to_h.deep_stringify_keys
      rules = data['rules']
      rules = rules.values if rules.is_a?(Hash)

      @match = MATCHES.include?(data['match']) ? data['match'] : 'all'
      @rules = Array(rules).filter_map do |rule|
        rule = rule.to_h.stringify_keys
        next if rule['variable'].blank? || !OPERATORS.include?(rule['operator'])

        Rule.new(variable: rule['variable'].strip, operator: rule['operator'], value: rule['value'].to_s.strip, value_to: rule['value_to'].to_s.strip)
      end
    end

    def to_h
      { 'match' => match, 'rules' => rules.map { |rule| rule.to_h.stringify_keys } }
    end

    def empty?
      rules.empty?
    end

    # Whether the context a setting is read with meets them: its assigns, or
    # a Lookup of them, to share between the refinements of one read
    def met?(assigns)
      return true if empty?

      lookup = assigns.is_a?(Lookup) ? assigns : Lookup.new(assigns)
      results = rules.lazy.map { |rule| compare(rule, lookup.value(rule.variable)) }
      (match == 'any') ? results.any? : results.all?
    end

    # The value of a variable in a context. Plain hashes are walked here, and
    # a record or drop at the end of a path is its id, so rules on ids and
    # scalars never build a drop. A path into a record or drop goes through
    # Liquid, built once, which only calls what a drop allows: a record
    # without a drop (to_liquid) gives nothing.
    class Lookup
      def initialize(assigns)
        @assigns = assigns.to_h.deep_stringify_keys
      end

      def value(variable)
        value = at(variable)
        value = at("#{variable}_id") if value.nil?
        identify(value)
      end

      private

      def at(variable)
        names = variable.split('.')
        value = @assigns
        names.each do |name|
          case value
          when Hash then value = value[name]
          when nil then return nil
          else return liquid(variable)
          end
        end
        value
      end

      def liquid(variable)
        @context ||= Liquid::Context.new([@assigns])
        value = @context[variable]
        value.respond_to?(:to_liquid) ? value.to_liquid : value
      rescue StandardError
        nil
      end

      # A record or drop is its id, also in a collection
      def identify(value)
        case value
        when Array then value.map { |element| identify(element) }
        when Liquid::Drop then value.invoke_drop('id')
        else (value.respond_to?(:to_key) && value.respond_to?(:id)) ? value.id : value
        end
      end
    end

    private

    def compare(rule, actual)
      case rule.operator
      when 'is_empty' then empty_value?(actual)
      when 'isnt_empty' then !empty_value?(actual)
      when 'is' then equal?(actual, rule.value)
      when 'isnt' then !equal?(actual, rule.value)
      when 'matches' then text(actual).include?(rule.value.downcase)
      when 'does_not_match' then !text(actual).include?(rule.value.downcase)
      when 'gt' then order(actual, rule.value)&.positive?
      when 'gteq' then order(actual, rule.value)&.>=(0)
      when 'lt' then order(actual, rule.value)&.negative?
      when 'lteq' then order(actual, rule.value)&.<=(0)
      when 'between'
        from = order(actual, rule.value)
        to = order(actual, rule.value_to)
        from && to && from >= 0 && to <= 0
      end || false
    end

    def empty_value?(actual)
      actual.nil? || (actual.respond_to?(:empty?) && actual.empty?)
    end

    # A collection is one of its elements; true and false also as yes or ja
    def equal?(actual, value)
      return actual.any? { |element| equal?(element, value) } if actual.is_a?(Array)
      return actual == TRUE_VALUES.include?(value.downcase) if [true, false].include?(actual)

      order(actual, value)&.zero? || text(actual) == value.downcase
    end

    def text(actual)
      Array(actual).join(', ').downcase
    end

    # actual <=> value, with value as a number, date or time when actual is
    def order(actual, value)
      other = case actual
              when Numeric then BigDecimal(value)
              when ActiveSupport::TimeWithZone, Time, DateTime then Time.zone.parse(value)
              when Date then Date.parse(value)
              when String then value
              end
      other.nil? ? nil : actual <=> other
    rescue ArgumentError, TypeError
      nil
    end
  end
end
