# frozen_string_literal: true

require 'test_helper'

module Vario
  # Values as their setting's type (ExamplesSettings has one of each)
  class ValueTest < ActiveSupport::TestCase
    def definition(key)
      Topic.definition(Account, "examples.#{key}")
    end

    def stored(key, value)
      setting = accounts(:boxture).settings.find_or_initialize_by(name: "examples.#{key}")
      setting.update!(value: value)
      [Setting.connection.select_value("SELECT value::text FROM vario_settings WHERE id = #{Setting.connection.quote(setting.id)}"), Setting.find(setting.id).value]
    end

    test 'nothing is nil, so the default applies' do
      [nil, '', '  ', [], {}].each do |value|
        %w[enabled quantity name cutoff_time working_days options owner].each do |key|
          assert_nil definition(key).cast(value), "#{key} #{value.inspect}"
        end
      end
      refute_nil definition('enabled').cast(false)
    end

    test 'a boolean' do
      assert_equal [true, true, true, false, false, false], [true, '1', 'true', false, '0', 'false'].map { |value| definition('enabled').cast(value) }
      assert_equal ['false', false], stored('enabled', '0')
      assert_equal ['true', true], stored('enabled', 'true')
    end

    test 'an integer' do
      assert_equal [13, 13, 13, 0], [13, '13', ' 13 ', 'abc'].map { |value| definition('quantity').cast(value) }
      assert_equal ['13', 13], stored('quantity', '13')
    end

    test 'a decimal, stored as text so it stays exact' do
      assert_equal BigDecimal('2.5'), definition('price').cast('2.50')
      assert_equal ['"2.5"', BigDecimal('2.5')], stored('price', '2.50')
      assert_equal ['"0.3"', BigDecimal('0.3')], stored('price', BigDecimal('0.1') + BigDecimal('0.2'))
    end

    test 'a text' do
      assert_equal ['"Boxture"', 'Boxture'], stored('name', 'Boxture')
      assert_equal "Line 1\nLine 2", definition('notes').cast("Line 1\nLine 2")
    end

    test 'a time of day, as 1.x stored it' do
      assert_equal %w[13:00 09:05 09:05 23:59], ['13:00', '9:05', '09.05', '23:59:00'].map { |value| definition('cutoff_time').cast(value) }
      assert_equal '15:30', definition('cutoff_time').cast(Time.utc(2026, 11, 18, 15, 30))
      assert_nil definition('cutoff_time').cast('25:00')
      assert_nil definition('cutoff_time').cast('noon')
      assert_equal ['"13:00"', '13:00'], stored('cutoff_time', '13:00')
    end

    test "an array, from 1.x also values separated by commas or lines" do
      assert_equal %w[1 2 3], definition('working_days').cast(%w[1 2 3])
      assert_equal %w[1 2 3], definition('working_days').cast("1, 2,\n3\n")
      assert_equal %w[1 2], definition('working_days').cast(['', '1', '2'])
      assert_equal ['["1", "2"]', %w[1 2]], stored('working_days', '1,2')
    end

    test "1.x's all of an array with choices is all of them" do
      setting = accounts(:boxture).settings.create!(name: 'examples.working_days', value: %w[all])

      assert_equal '["all"]', Setting.connection.select_value("SELECT value::text FROM vario_settings WHERE id = #{Setting.connection.quote(setting.id)}")
      assert_equal %w[1 2 3 4 5 6 7], Setting.find(setting.id).value
    end

    test 'a hash, from 1.x also YAML' do
      assert_equal({ 'a' => 1, 'b' => { 'c' => 'd' } }, definition('options').cast("a: 1\nb:\n  c: d\n"))
      assert_equal({ 'a' => 1 }, definition('options').cast(a: 1))
      assert_nil definition('options').cast('just text')
      assert_nil definition('options').cast("a: [unclosed\n")
      assert_equal ['{"a": 1}', { 'a' => 1 }], stored('options', 'a: 1')
    end

    test 'a record, by its id' do
      account = accounts(:skepr)

      assert_equal account.id, definition('owner').cast(account)
      assert_equal account.id, definition('owner').cast(account.id)
      assert_nil definition('owner').cast('not-an-id')
      assert_equal ["\"#{account.id}\"", account.id], stored('owner', account)
    end

    test 'choices, as values or labels and values' do
      assert_equal %w[small medium large], definition('size').choice_values
      assert_equal %w[1 2 3 4 5 6 7], definition('working_days').choice_values
      assert_equal %w[Monday 1], definition('working_days').choices_for.first
    end

    test 'choices from a lambda, which may take the settable' do
      plain = Topic::Definition.new(ExamplesSettings, :plain, :string, choices: -> { %w[a b] })
      per_settable = Topic::Definition.new(ExamplesSettings, :per_settable, :string, choices: ->(settable) { [settable.name] })

      assert_equal %w[a b], plain.choice_values
      assert_equal ['Boxture'], per_settable.choice_values(accounts(:boxture))
    end

    test 'the default, as the type' do
      assert_equal 1, definition('quantity').default_value
      assert_equal false, definition('enabled').default_value
      assert_equal %w[1 2 3 4 5], definition('working_days').default_value
      assert_nil definition('price').default_value
    end

    test 'cast when saved, whatever the order of the attributes' do
      setting = Setting.create!(value: '13', name: 'examples.quantity', settable: accounts(:boxture))

      assert_equal 13, Setting.find(setting.id).value
      assert_equal '13', Setting.connection.select_value("SELECT value::text FROM vario_settings WHERE id = #{Setting.connection.quote(setting.id)}")
    end

    test "a refinement's value is its setting's type" do
      setting = accounts(:boxture).settings.create!(name: 'examples.quantity', value: '1', refinements_attributes: [{ value: '5' }])

      refinement = Setting.find(setting.id).refinements.first
      assert_equal 5, refinement.value
      assert_equal '5', Setting.connection.select_value("SELECT value::text FROM vario_refinements WHERE id = #{Setting.connection.quote(refinement.id)}")
    end
  end
end
