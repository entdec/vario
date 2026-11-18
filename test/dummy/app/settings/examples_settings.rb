# frozen_string_literal: true

# A setting of every type
class ExamplesSettings < Vario::Topic
  settable Account
  icon 'fal fa-flask'
  context environment: :string, product: Product

  setting :enabled, :boolean, default: false
  setting :quantity, :integer, default: 1
  setting :price, :decimal
  setting :name, :string
  setting :notes, :text
  setting :cutoff_time, :time, default: '13:00'
  setting :working_days, :array, default: %w[1 2 3 4 5], choices: [%w[Monday 1], %w[Tuesday 2], %w[Wednesday 3], %w[Thursday 4], %w[Friday 5], %w[Saturday 6], %w[Sunday 7]]
  setting :options, :hash
  setting :owner, Account
  setting :size, :string, choices: %w[small medium large]
end
