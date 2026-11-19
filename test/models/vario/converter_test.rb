# frozen_string_literal: true

require 'test_helper'

module Vario
  class ConverterTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:boxture)
      @product = products(:apple)
      @legacy_keys = Vario.config.legacy_keys.dup
      Vario.config.legacy_key :customer_id, 'order.customer'
    end

    teardown do
      Vario.config.legacy_keys.replace(@legacy_keys)
    end

    def row(name, keys, levels)
      id = Setting.insert!({ settable_type: 'Account', settable_id: @account.id, name: name, keys: keys, levels: levels }, returning: :id).first['id']
      Setting.find(id)
    end

    def rules(refinement)
      refinement[:conditions]['rules'].map { |rule| rule.values_at('variable', 'operator', 'value') }
    end

    test 'levels before the first without conditions are refinements, it the value, those after dead' do
      setting = row('examples.quantity', %w[order_type product_id customer_id], [
        { conditions: { order_type: 'SalesOrder', product_id: @product.id }, value: '9' },
        { conditions: { customer_id: '5' }, value: '5' },
        { conditions: {}, value: '3' },
        { conditions: { order_type: 'ReturnOrder' }, value: '7' },
        { conditions: {}, value: '4' }
      ])
      conversion = Converter.new(setting).call

      assert_equal '3', conversion.value
      assert_equal [['9', true, nil], ['5', true, nil], ['7', false, Converter::DEAD_NOTE], ['4', false, Converter::DEAD_NOTE]],
                   conversion.refinements.map { |refinement| refinement.values_at(:value, :enabled, :note) }
      assert_equal [[['order_type', 'is', 'SalesOrder'], ['product', 'is', @product.id]], [['order.customer', 'is', '5']], [%w[order_type is ReturnOrder]], []],
                   conversion.refinements.map { |refinement| rules(refinement) }
      assert_equal [2, 0, [], false], [conversion.dead, conversion.empty, conversion.uncastable, conversion.unknown?]
    end

    test 'applied: the value and refinements as their type, the levels as they were' do
      levels = [{ 'conditions' => { 'order_type' => 'SalesOrder' }, 'value' => '9' }, { 'conditions' => {}, 'value' => '3' },
                { 'conditions' => {}, 'value' => '3' }]
      setting = row('examples.quantity', %w[order_type], levels)

      Converter.new(setting).call.apply!
      setting = Setting.find(setting.id)

      assert_equal 3, setting.value
      assert_equal [[1, 9, true], [2, 3, false]], setting.refinements.map { |refinement| [refinement.position, refinement.value, refinement.enabled] }
      assert_equal levels, setting.attributes['levels']
    end

    test 'applied again, the same' do
      setting = row('examples.quantity', %w[order_type], [{ conditions: { order_type: 'SalesOrder' }, value: '9' }, { conditions: {}, value: '3' }])

      Converter.new(setting).call.apply!
      Converter.new(Setting.find(setting.id)).call.apply!

      assert_equal [9], Setting.find(setting.id).refinements.map(&:value)
    end

    test "levels without a value don't count, but one without conditions still makes the rest dead" do
      setting = row('examples.quantity', %w[order_type], [
        { conditions: { order_type: 'SalesOrder' }, value: '' },
        { conditions: {}, value: nil },
        { conditions: { order_type: 'ReturnOrder' }, value: '7' }
      ])
      conversion = Converter.new(setting).call

      assert_nil conversion.value
      assert_equal [[['7', false]], 1, 2], [conversion.refinements.map { |refinement| refinement.values_at(:value, :enabled) }, conversion.dead, conversion.empty]
    end

    test "conditions on keys the setting no longer has don't count, as in 1.x" do
      setting = row('examples.quantity', %w[order_type], [{ conditions: { order_type: 'SalesOrder', location_id: '12', customer_id: '' }, value: '9' }])

      assert_equal [[%w[order_type is SalesOrder]]], Converter.new(setting).call.refinements.map { |refinement| rules(refinement) }
    end

    test 'values that are not what they say' do
      assert_equal ['abc', '2,5'], Converter.new(row('examples.quantity', [], [{ conditions: {}, value: '12' }, { conditions: {}, value: 'abc' }, { conditions: {}, value: '2,5' }])).call.uncastable
      assert_equal ['off'], Converter.new(row('examples.enabled', [], [{ conditions: {}, value: '1' }, { conditions: {}, value: 'off' }, { conditions: {}, value: false }])).call.uncastable
      assert_equal ['noon'], Converter.new(row('examples.cutoff_time', [], [{ conditions: {}, value: '9:05' }, { conditions: {}, value: 'noon' }])).call.uncastable
      assert_equal ['2,5'], Converter.new(row('examples.price', [], [{ conditions: {}, value: '2.5' }, { conditions: {}, value: '2,5' }])).call.uncastable
      assert_equal ['just text'], Converter.new(row('examples.options', [], [{ conditions: {}, value: 'just text' }])).call.uncastable
    end

    test 'a setting no topic defines is left alone' do
      setting = row('nothing.here', [], [{ conditions: {}, value: '1' }])
      conversion = Converter.new(setting).call

      assert conversion.unknown?
      assert_raises(Error) { conversion.apply! }
      assert_nil Setting.find(setting.id)[:value]
    end
  end
end
