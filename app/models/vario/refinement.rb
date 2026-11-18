# frozen_string_literal: true

module Vario
  # A more specific value of a setting: its value applies when its conditions
  # (Vario::Conditions) are met, the first enabled one by position
  class Refinement < ApplicationRecord
    belongs_to :setting, inverse_of: :refinements

    positioned on: :setting
  end
end
