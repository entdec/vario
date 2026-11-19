# frozen_string_literal: true

require 'test_helper'

module Vario
  class ResolverTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:boxture)
      @context_defaults = Vario.config.context_defaults.dup
      @legacy_keys = Vario.config.legacy_keys.dup
    end

    teardown do
      Vario.config.context_defaults.replace(@context_defaults)
      Vario.config.legacy_keys.replace(@legacy_keys)
    end

    def rule(variable, value, operator: 'is')
      { match: 'all', rules: [{ variable: variable, operator: operator, value: value }] }
    end

    def quantity(value: nil, refinements: [])
      @account.settings.create!(name: 'examples.quantity', value: value, refinements_attributes: refinements)
      @account.reload
    end

    test "the definition's default, else the one it's read with" do
      resolution = @account.explain('examples.quantity')
      assert_equal [1, :default, nil], [resolution.value, resolution.source, resolution.refinement]

      assert_equal 7, @account.explain('examples.quantity', default: '7').value
      assert_nil @account.explain('examples.price').value
    end

    test "the settable's own value" do
      quantity(value: 3)

      assert_equal [3, :value], @account.explain('examples.quantity').then { |resolution| [resolution.value, resolution.source] }
      assert_equal 3, @account.explain('examples.quantity', default: 7).value
    end

    test 'the first enabled refinement whose conditions are met, by position' do
      quantity(value: 3, refinements: [
        { value: 20, conditions: rule('order_type', 'SalesOrder'), enabled: false },
        { value: 10, conditions: rule('order_type', 'SalesOrder') },
        { value: 30, conditions: rule('order_type', 'ReturnOrder') },
        { value: nil, conditions: rule('order_type', 'TransferOrder') },
        { value: 50, conditions: { match: 'any', rules: [] } }
      ])

      sales = @account.explain('examples.quantity', order_type: 'SalesOrder')
      assert_equal [10, :refinement, 2], [sales.value, sales.source, sales.refinement.position]
      assert_equal 30, @account.explain('examples.quantity', order_type: 'ReturnOrder').value
      # Without a value, a refinement doesn't apply; without conditions it always does
      assert_equal [50, 5], @account.explain('examples.quantity', order_type: 'TransferOrder').then { |resolution| [resolution.value, resolution.refinement.position] }
      assert_equal 50, @account.explain('examples.quantity').value
    end

    test 'without a refinement that applies, its own value' do
      quantity(value: 3, refinements: [{ value: 10, conditions: rule('order_type', 'SalesOrder') }])

      assert_equal [3, :value], @account.explain('examples.quantity', order_type: 'ReturnOrder').then { |resolution| [resolution.value, resolution.source] }
    end

    test 'a refinement on a record, read with the record or its id' do
      location = accounts(:skepr)
      quantity(refinements: [{ value: 10, conditions: rule('location', location.id) }])

      assert_equal 10, @account.explain('examples.quantity', location: location).value
      assert_equal 10, @account.explain('examples.quantity', location_id: location.id).value
      assert_equal 1, @account.explain('examples.quantity', location_id: @account.id).value
    end

    test "1.x's keys meet refinements on the variables they are now" do
      Vario.config.legacy_key :customer_id, 'order.customer'
      quantity(refinements: [{ value: 10, conditions: rule('order.customer', '5') },
                             { value: 20, conditions: { match: 'all', rules: [{ variable: 'order.customer', operator: 'is', value: '6' }, { variable: 'order.channel', operator: 'is', value: 'web' }] } }])

      assert_equal 10, @account.explain('examples.quantity', customer_id: 5).value
      assert_equal 20, @account.explain('examples.quantity', customer_id: 6, order: { channel: 'web' }).value
      assert_equal 1, @account.explain('examples.quantity', customer_id: 7).value
    end

    test 'a context root it is read without has its default, for settings with that root' do
      Vario.config.context_default :environment, -> { 'staging' }
      quantity(refinements: [{ value: 10, conditions: rule('environment', 'staging') }])
      @account.settings.create!(name: 'hide_couriers', value: true, refinements_attributes: [{ value: false, conditions: rule('environment', 'staging') }])
      @account.reload

      assert_equal 10, @account.explain('examples.quantity').value
      assert_equal 10, @account.explain('examples.quantity', environment: nil).value
      assert_equal 1, @account.explain('examples.quantity', environment: 'production').value
      # hide_couriers' topic has no environment in its context
      assert_equal true, @account.explain('hide_couriers').value
    end

    test 'an unknown setting' do
      assert_raises(UnknownSetting) { @account.explain('examples.nothing') }
      assert_raises(UnknownSetting) { @account.explain('nothing') }
    end

    test "reading loads all of a settable's settings once, and creates none" do
      quantity(value: 3, refinements: [{ value: 10, conditions: rule('order_type', 'SalesOrder') }])
      @account.settings.create!(name: 'examples.enabled', value: true)
      @account.reload

      assert_queries_count(2) do
        @account.explain('examples.quantity', order_type: 'SalesOrder')
        @account.explain('examples.enabled')
        @account.explain('examples.name')
      end
      assert_no_difference -> { Setting.count } do
        accounts(:skepr).explain('examples.quantity')
      end
    end

    test 'reload reads them again' do
      quantity(value: 3)
      assert_equal 3, @account.explain('examples.quantity').value

      Setting.find_by(name: 'examples.quantity').update!(value: 4)
      assert_equal 3, @account.explain('examples.quantity').value
      assert_equal 4, @account.reload.explain('examples.quantity').value
    end

    test "a topic's settings by their keys" do
      quantity(value: 3)
      reader = @account.settings(:examples, order_type: 'SalesOrder')

      assert_equal 3, reader.quantity
      assert_equal 3, reader[:quantity]
      assert_equal false, reader.enabled?
      assert_equal '13:00', reader.cutoff_time
      assert reader.respond_to?(:quantity)
      assert_raises(NoMethodError) { reader.nothing }
      assert_raises(UnknownSetting) { reader[:nothing] }
      assert_raises(UnknownSetting) { @account.settings(:nothing) }
    end

    test 'settings without arguments are the rows' do
      quantity(value: 3)

      assert_equal %w[examples.quantity], @account.settings.map(&:name)
      assert_kind_of ActiveRecord::Associations::CollectionProxy, @account.settings
    end
  end
end
