# frozen_string_literal: true

require 'test_helper'

class ProductDrop < Liquid::Drop
end

# A topic of the tests' own, on another settable, with drops and models
class StockSettings < Vario::Topic
  settable Product
  icon 'fal fa-boxes'
  context product: ProductDrop, account: :string, order_type: :string

  setting :reorder_level, :integer, default: 0
  setting :default_account, Account, context: %i[account]
  setting :units, :array, choices: -> { %w[piece box] }
end

module Vario
  class TopicTest < ActiveSupport::TestCase
    test "the app's topics, from app/settings, and the tests' own" do
      assert_includes Topic.registered, PrintNodeSettings
      assert_includes Topic.registered, GeneralSettings
      assert_includes Topic.registered, StockSettings
    end

    test 'the topics of a settable, its record or its class, by title' do
      assert_equal [GeneralSettings, PrintNodeSettings], Topic.for(Account)
      assert_equal [GeneralSettings, PrintNodeSettings], Topic.for(accounts(:boxture))
      assert_equal [StockSettings], Topic.for(products(:apple))
      assert_equal PrintNodeSettings, Topic.find(Account, :print_node)
      assert_nil Topic.find(Product, :print_node)
    end

    test 'a topic is its class name without Settings' do
      assert_equal 'print_node', PrintNodeSettings.key
      assert_equal 'stock', StockSettings.key
      assert_equal 'Account', PrintNodeSettings.settable
      assert_equal Account, PrintNodeSettings.settable_class
      assert_equal 'fal fa-print', PrintNodeSettings.icon
    end

    test 'its settings by name, in the order they are defined' do
      assert_equal %w[stock.reorder_level stock.default_account stock.units], StockSettings.definitions.keys

      definition = Topic.definition(Product, 'stock.reorder_level')
      assert_equal StockSettings, definition.topic
      assert_equal 'reorder_level', definition.key
      assert_equal :integer, definition.type
      assert_equal 0, definition.default
      assert_nil definition.model

      assert_nil Topic.definition(Account, 'stock.reorder_level')
      assert_nil Topic.definition(Product, 'stock.nothing')
    end

    test 'a setting may have a name of its own, from 1.x' do
      definition = Topic.definition(Account, 'hide_couriers')

      assert_equal GeneralSettings, definition.topic
      assert_equal 'hide_couriers', definition.key
      assert definition.default
    end

    test 'a model as type, and choices' do
      assert_equal Account, Topic.definition(Product, 'stock.default_account').model
      assert_equal %w[piece box], Topic.definition(Product, 'stock.units').choices.call
    end

    test "what refinements may look at: the topic's context, or the part a setting names" do
      assert_equal({ 'product' => ProductDrop, 'account' => :string, 'order_type' => :string }, StockSettings.context)
      assert_equal StockSettings.context, Topic.definition(Product, 'stock.reorder_level').context
      assert_equal({ 'account' => :string }, Topic.definition(Product, 'stock.default_account').context)
      assert_equal({}, GeneralSettings.context)
    end

    test 'texts from the locale files, else from the keys' do
      assert_equal 'PrintNode', PrintNodeSettings.title
      assert_equal 'Printing labels and documents through PrintNode.', PrintNodeSettings.description
      assert_equal 'API key', Topic.definition(Account, 'print_node.api_key').label
      assert_equal 'The key of the PrintNode account to print with.', Topic.definition(Account, 'print_node.api_key').description

      assert_equal 'Stock', StockSettings.title
      assert_nil StockSettings.description
      assert_equal 'Reorder level', Topic.definition(Product, 'stock.reorder_level').label
      assert_nil Topic.definition(Product, 'stock.reorder_level').description
    end

    test 'an unknown type' do
      error = assert_raises(ArgumentError) { StockSettings.setting :colour, :colour }
      assert_match(/Unknown type :colour for setting colour of StockSettings/, error.message)
      refute StockSettings.definitions.key?('stock.colour')
    end

    test 'load! drops a topic a reload replaced' do
      old = Class.new(Topic) { settable Account }
      Object.const_set(:ReloadedSettings, old)
      Object.send(:remove_const, :ReloadedSettings)
      new = Class.new(Topic) { settable Account }
      Object.const_set(:ReloadedSettings, new)

      Topic.load!

      assert_includes Topic.registered, new
      refute_includes Topic.registered, old
      assert_includes Topic.registered, PrintNodeSettings
    ensure
      Object.send(:remove_const, :ReloadedSettings) if Object.const_defined?(:ReloadedSettings)
      Topic.registered.delete(new)
    end
  end
end
