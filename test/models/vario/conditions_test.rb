# frozen_string_literal: true

require 'test_helper'

module Vario
  class ConditionsTest < ActiveSupport::TestCase
    # The cases are flow forms' and Nuntius' too: its rule cases, on one input
    # x of a type, filled in with value, as flow forms' Submission types it.
    # Its design cases are about a form's blocks, which vario doesn't have.
    CASES = JSON.parse(File.read(File.expand_path('../../fixtures/files/conditions_cases.json', __dir__)))

    class Choices < ActiveModel::Type::Value
      def cast(value) = Array(value).map(&:to_s).compact_blank
    end

    TYPES = {
      'flow_short_text' => :string, 'flow_long_text' => :string, 'flow_email' => :string, 'flow_phone' => :string,
      'flow_hidden' => :string, 'flow_single_choice' => :string, 'flow_number' => :decimal, 'flow_rating' => :decimal,
      'flow_scale' => :decimal, 'flow_date' => :date, 'flow_yes_no' => :boolean, 'flow_consent' => :boolean
    }.freeze

    def self.typed(example)
      return if example['value'].nil?
      return Choices.new.cast(example['value']) if example['input'] == 'flow_multiple_choice'

      ActiveModel::Type.lookup(TYPES.fetch(example['input'])).cast(example['value'])
    end

    CASES['rules'].each do |example|
      test "a rule: #{example['name']}" do
        rules = example['rules']
        with_variable = ->(rule) { { 'variable' => 'x' }.merge(rule) }
        rules = rules.is_a?(Hash) ? rules.transform_values(&with_variable) : rules.map(&with_variable)
        conditions = Conditions.new({ 'match' => example['match'], 'rules' => rules }.compact)

        assert_equal example['met'], conditions.met?('x' => self.class.typed(example))
      end
    end

    class CustomerDrop < Liquid::Drop
      def initialize(id)
        @id = id
      end

      attr_reader :id

      def country
        'NL'
      end
    end

    class OrderDrop < Liquid::Drop
      def initialize(customer_id)
        @customer_id = customer_id
      end

      def customer
        CustomerDrop.new(@customer_id) if @customer_id
      end

      def business_model
        'b2b'
      end
    end

    def on(variable, value, operator: 'is')
      Conditions.new('rules' => [{ 'variable' => variable, 'operator' => operator, 'value' => value }])
    end

    test 'a record is its id' do
      account = accounts(:boxture)

      assert on('location', account.id).met?(location: account)
      refute on('location', accounts(:skepr).id).met?(location: account)
      assert on('location', accounts(:skepr).id, operator: 'isnt').met?(location: account)
    end

    test 'without the record, its _id' do
      assert on('location', '5').met?(location_id: 5)
      refute on('location', '6').met?(location_id: 5)
      assert on('order.customer', '5').met?(order: { customer_id: 5 })
    end

    test 'a drop is its id, and a path walks into it' do
      assert on('order.customer', '5').met?(order: OrderDrop.new(5))
      assert on('order.customer.country', 'nl').met?(order: OrderDrop.new(5))
      assert on('order.business_model', 'B2B').met?(order: OrderDrop.new(5))
      assert on('order.customer', nil, operator: 'is_empty').met?(order: OrderDrop.new(nil))
    end

    test 'rules on ids and plain values build no Liquid context' do
      lookup = Conditions::Lookup.new(location: accounts(:boxture), order_type: 'SalesOrder', order: { customer_id: 5 })

      assert on('location', accounts(:boxture).id).met?(lookup)
      assert on('order_type', 'salesorder').met?(lookup)
      assert on('order.customer', '5').met?(lookup)
      assert_nil lookup.instance_variable_get(:@context)

      lookup = Conditions::Lookup.new(order: OrderDrop.new(5))
      assert on('order.customer.country', 'NL').met?(lookup)
      assert on('order.business_model', 'b2b').met?(lookup)
      assert_instance_of Liquid::Context, lookup.instance_variable_get(:@context)
    end

    test 'a record without a drop gives nothing further, and calls nothing on it' do
      account = accounts(:boxture)

      refute on('account.name', 'Boxture').met?(account: account)
      refute on('account.destroy', 'x', operator: 'isnt_empty').met?(account: account)
      assert Account.exists?(account.id)
    end

    test 'a variable that is not there is empty' do
      assert on('order.channel', nil, operator: 'is_empty').met?({})
      refute on('order.channel', 'web').met?(order: OrderDrop.new(5))
    end

    test 'any of the rules' do
      conditions = Conditions.new('match' => 'any', 'rules' => [{ 'variable' => 'x', 'operator' => 'is', 'value' => '1' },
                                                                { 'variable' => 'y', 'operator' => 'is', 'value' => '2' }])

      assert conditions.met?(x: 3, y: 2)
      refute conditions.met?(x: 3, y: 3)
    end

    test 'the form gives numbered rules; unknown operators and rules without a variable are left out' do
      conditions = Conditions.new('match' => 'nonsense', 'rules' => { '0' => { 'variable' => ' location ', 'operator' => 'is', 'value' => ' 5 ' },
                                                                       '1' => { 'variable' => 'x', 'operator' => 'drop_table' },
                                                                       '2' => { 'variable' => '', 'operator' => 'is' } })

      assert_equal({ 'match' => 'all', 'rules' => [{ 'variable' => 'location', 'operator' => 'is', 'value' => '5', 'value_to' => '' }] }, conditions.to_h)
    end

    test 'no rules are met by anything' do
      assert Conditions.new.met?({})
      assert Conditions.new.empty?
    end
  end
end
