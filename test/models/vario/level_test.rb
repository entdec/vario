# frozen_string_literal: true

require 'test_helper'
require 'vario'

module Vario
  class LevelTest < ActiveSupport::TestCase
    setup do
      Vario.setup do |config|
        config.key :name, name: 'Name', type: :select, collection_proc: -> { [%w[Andre andre] %w[Mark mark] %w[Tom tom]] }
        config.key :day, name: 'Day', type: :string

        config.setting 'lucky_number', keys: %i[name day], type: :integer
        config.setting 'says_hi', type: :boolean, keys: %i[name day]
      end

      @lucky_number_setting = Setting.new(name: 'lucky_number')
      @says_hi_setting      = Setting.new(name: 'says_hi')
    end

    test 'new level with conditions' do
      level = Level.new(@lucky_number_setting, { value: 7, conditions: { name: 'andre', day: 'monday' } }, true)

      assert_equal({ name: 'andre', day: 'monday' }, level.conditions_hash)
    end

    test 'conditions_for selects conditions based on keys' do
      level = Level.new(@lucky_number_setting, { value: 7, conditions: { name: 'andre', day: 'monday' } }, true)

      conditions = level.conditions_for(name: 'mark')
      assert_equal 1, conditions.size
      assert_equal 'name', conditions.first.key
      assert_equal 'andre', conditions.first.value

      conditions = level.conditions_for(day: 'tuesday')
      assert_equal 1, conditions.size
      assert_equal 'day', conditions.first.key
      assert_equal 'monday', conditions.first.value
    end

    test 'conditions_not_for selects conditions based on other keys' do
      level = Level.new(@lucky_number_setting, { value: 7, conditions: { name: 'andre', day: 'monday' } }, true)

      conditions = level.conditions_not_for(name: 'mark')
      assert_equal 1, conditions.size
      assert_equal 'day', conditions.first.key
      assert_equal 'monday', conditions.first.value

      conditions = level.conditions_not_for(day: 'tuesday')
      assert_equal 1, conditions.size
      assert_equal 'name', conditions.first.key
      assert_equal 'andre', conditions.first.value
    end

    test 'with_context_values? matches only if all given context values match' do
      level = Level.new(@lucky_number_setting, { value: 7, conditions: { name: 'andre', day: 'monday' } }, true)

      assert level.with_context_values?(name: 'andre')
      assert level.with_context_values?(day: 'monday')
      assert level.with_context_values?(name: 'andre', day: 'monday')

      refute level.with_context_values?(name: 'mark')
      refute level.with_context_values?(day: 'tuesday')
      refute level.with_context_values?(name: 'mark', day: 'monday')
      refute level.with_context_values?(name: 'andre', day: 'tuesday')
    end

    test 'value_present? with an integer value' do
      level = Level.new(@lucky_number_setting, { value: 7, conditions: { name: 'andre', day: 'monday' } }, true)
      assert level.value_present?
      assert level.value.present?

      level.value = 0
      assert level.value_present?
      assert level.value.present?

      level.value = nil
      refute level.value_present?
      refute level.value.present?
    end

    test 'value_present? with a boolean value' do
      level = Level.new(@says_hi_setting, { value: true, conditions: { name: 'andre', day: 'monday' } }, true)
      assert level.value_present?
      assert level.value.present?

      # this is the main use case for value_present? on Level, a boolean false is a present value!
      level.value = false
      assert level.value_present?
      refute level.value.present?

      level.value = nil
      refute level.value_present?
      refute level.value.present?
    end
  end
end
