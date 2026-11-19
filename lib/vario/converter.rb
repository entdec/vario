# frozen_string_literal: true

module Vario
  # Converts a 1.x setting's levels to its own value and refinements, so it
  # reads the same:
  #
  # - the levels in order: those with conditions before the first one
  #   without become refinements (match all, an is rule per key), that one
  #   the value
  # - the levels after it never applied in 1.x (the first without conditions
  #   matches everything): they become refinements too, disabled, with a note
  # - keys become the variables they are now (Topic::Definition#variable_for)
  # - values are cast to the setting's type
  #
  #   conversion = Converter.new(setting).call
  #   conversion.dead        # => 1
  #   conversion.apply!
  #
  # A setting no topic defines isn't converted (unknown?).
  class Converter
    DEAD_NOTE = 'Was niet actief in Vario 1'

    def initialize(setting)
      @setting = setting
      @definition = setting.definition
    end

    def call
      return Conversion.new(setting: @setting, value: nil, refinements: [], dead: 0, empty: 0, uncastable: [], unknown: true) unless @definition

      value = nil
      refinements = []
      empty = 0
      uncastable = []
      cut = false

      levels.each do |level|
        conditions = conditions_of(level)

        unless value_present?(level['value'])
          # 1.x didn't save these; one without conditions still made the rest dead
          empty += 1
          cut ||= conditions.empty?
          next
        end
        uncastable << level['value'] unless castable?(level['value'])

        if cut || conditions.any?
          refinements << { conditions: { 'match' => 'all', 'rules' => rules_for(conditions) }, value: level['value'], enabled: !cut, note: (DEAD_NOTE if cut) }
        else
          value = level['value']
          cut = true
        end
      end

      Conversion.new(setting: @setting, value: value, refinements: refinements, dead: refinements.count { |refinement| !refinement[:enabled] },
                     empty: empty, uncastable: uncastable, unknown: false)
    end

    private

    def levels
      Array(@setting.attributes['levels']).map { |level| level.to_h.stringify_keys }
    end

    # As 1.x saw them: of the setting's keys, the ones with a value
    def conditions_of(level)
      conditions = (level['conditions'] || {}).to_h.stringify_keys
      keys = Array(@setting.keys).map(&:to_s)
      conditions.slice(*keys).reject { |_key, value| value.blank? }
    end

    def rules_for(conditions)
      conditions.map { |key, value| { 'variable' => @definition.variable_for(key), 'operator' => 'is', 'value' => value } }
    end

    def value_present?(value)
      value == false || value.present?
    end

    # Whether the cast keeps what it says, and what 1.x read: not "abc" as
    # 0, "2,5" as 2, "off" as false (1.x knew only 0, 1, true and false) or
    # a time that isn't one
    def castable?(value)
      return false if @definition.cast(value).nil?
      return true unless value.is_a?(String)

      case @definition.type
      when :integer then value.match?(/\A\s*[+-]?\d+\s*\z/)
      when :decimal then value.match?(/\A\s*[+-]?\d+(\.\d+)?\s*\z/)
      when :boolean then %w[0 1 true false].include?(value)
      else true
      end
    end
  end

  # What a setting converts to (Converter), and what came up
  Conversion = Data.define(:setting, :value, :refinements, :dead, :empty, :uncastable, :unknown) do
    alias_method :unknown?, :unknown

    # Its value and refinements, instead of those it has. Its levels stay as
    # they are (1.x's callbacks on the setting would change them).
    def apply!
      raise Error, "Setting '#{setting.name}' is not defined for #{setting.settable_type}" if unknown?

      Setting.transaction do
        setting.refinements.destroy_all
        setting.update_columns(value: setting.definition.serialize(value), updated_at: Time.current)
        refinements.each_with_index { |refinement, index| setting.refinements.create!(refinement.merge(position: index + 1)) }
      end
    end
  end
end
