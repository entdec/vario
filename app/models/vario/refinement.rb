# frozen_string_literal: true

module Vario
  # A more specific value of a setting: its value applies when its conditions
  # (Vario::Conditions) are met, the first enabled one by position
  class Refinement < ApplicationRecord
    belongs_to :setting, inverse_of: :refinements

    positioned on: :setting

    before_validation :serialize_value

    delegate :definition, to: :setting, allow_nil: true

    # Its value, as the setting's type
    def value
      definition ? definition.read(self[:value]) { setting.settable } : self[:value]
    end

    # A record is its id (the jsonb column would take it as JSON)
    def value=(value)
      super(value.is_a?(ActiveRecord::Base) ? value.id : value)
    end

    private

    def serialize_value
      self[:value] = definition.serialize(self[:value]) if definition
    end
  end
end
