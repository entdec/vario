# frozen_string_literal: true

require 'test_helper'

module Vario
  class ContextVariablesTest < ActiveSupport::TestCase
    # A drop for an account, with its owner (an account too)
    class OwnerDrop < Liquidum::Drop
      def self.model = Account

      def name = @object.name
    end

    class AccountDrop < Liquidum::Drop
      def self.model = Account

      describe :owner, drop: 'Vario::ContextVariablesTest::OwnerDrop'

      def name = @object.name

      def owner = OwnerDrop.new(@object)
    end

    setup do
      @variables = ContextVariables.new(account: AccountDrop, product: Product, order_type: :string)
    end

    test 'the roots: a drop and a model are objects, a plain value its type' do
      assert_equal [%w[account object true], %w[product object false], %w[order_type string false]],
                   @variables.at('').map { |variable| [variable.name, variable.type, variable.as_json[:children].to_s] }
      assert_equal [], @variables.at('product')
    end

    test "a drop's variables, a level at a time" do
      assert_equal %w[id name owner], @variables.at('account').map(&:name)
      assert_equal %w[id name], @variables.at('account.owner').map(&:name)
    end

    test 'a variable described: its labels on the way, and its type' do
      assert_equal ['Account › Owner', 'object'], @variables.describe('account.owner')
      assert_equal ['Product', 'object'], @variables.describe('product')
      assert_equal ['Order type', 'string'], @variables.describe('order_type')
      assert_equal ['nothing.here', nil], @variables.describe('nothing.here')
    end

    test "an object's model, whose records it can be" do
      assert_equal Account, @variables.model('account')
      assert_equal Account, @variables.model('account.owner')
      assert_equal Product, @variables.model('product')
      assert_nil @variables.model('order_type')
      assert_nil @variables.model('account.name')
    end
  end
end
