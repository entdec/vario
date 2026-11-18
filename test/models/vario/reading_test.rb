# frozen_string_literal: true

require 'test_helper'

module Vario
  # 1.x's ways to read settings, on the resolver
  class ReadingTest < ActiveSupport::TestCase
    # Reads Account settings, as Boxture's Order does
    class Shipment
      include Vario::SettingsReader

      attr_reader :account, :product, :settings

      def initialize(account, product: nil, settings: {})
        @account = account
        @product = product
        @settings = settings
      end

      settings_reader Account, %w[examples.quantity examples.enabled]
    end

    # Answers for its product by id, as Boxture's Location does for itself
    class Line
      include Vario::SettingsReader

      attr_reader :account, :product_id

      def initialize(account, product_id)
        @account = account
        @product_id = product_id
      end

      settings_reader Account, %w[examples.quantity]
    end

    # Is the root itself, as an Order is for order
    class Kit < ::Product
      attr_accessor :account

      settings_reader Account, %w[examples.quantity]
    end

    setup do
      @account = accounts(:boxture)
      @product = products(:apple)
      @account.settings.create!(name: 'examples.quantity', value: 3, refinements_attributes: [
        { value: 10, conditions: { match: 'all', rules: [{ variable: 'product', operator: 'is', value: @product.id }] } }
      ])
      @account.reload
    end

    test 'setting, with a context and a default' do
      assert_equal 3, @account.setting('examples.quantity')
      assert_equal 10, @account.setting(:'examples.quantity', product_id: @product.id)
      assert_equal 10, @account.setting('examples.quantity', 'product' => @product)
      assert_equal 7, @account.setting('examples.price', default: '7')
      assert_raises(UnknownSetting) { @account.setting('examples.nothing') }
    end

    test "setting doesn't change the context it's given" do
      context = { 'product_id' => @product.id, default: 1 }
      @account.setting('examples.quantity', context)

      assert_equal({ 'product_id' => @product.id, default: 1 }, context)
    end

    test "settings_hash, a topic's values by key" do
      hash = @account.settings_hash('examples', product_id: @product.id)

      assert_equal 10, hash[:quantity]
      assert_equal 10, hash['quantity']
      assert_equal '13:00', hash[:cutoff_time]
      assert_equal ExamplesSettings.definitions.size, hash.size
      assert_raises(ArgumentError) { @account.settings_hash('examples', default: 1) }
      assert_raises(UnknownSetting) { @account.settings_hash('nothing') }
    end

    test "1.x's cache methods create nothing" do
      assert_no_difference -> { Setting.count } do
        @account.setting('examples.enabled')
        @account.settings_prepopulate_cache
        @account.settings_save_unsaved
      end
    end

    test "settings_reader, in the reading object's context" do
      assert_equal 3, Shipment.new(@account).quantity
      assert_equal 10, Shipment.new(@account, product: @product).quantity
      assert_equal 10, Line.new(@account, @product.id).quantity
      assert_equal 10, Kit.find(@product.id).tap { |kit| kit.account = @account }.quantity
      assert_equal 3, Kit.find(products(:orange).id).tap { |kit| kit.account = @account }.quantity
      assert_equal false, Shipment.new(@account).enabled?
      refute Shipment.method_defined?(:enabled)
    end

    test "settings_reader, the object's own settings first" do
      assert_equal 42, Shipment.new(@account, settings: { 'examples' => { 'quantity' => 42 } }).quantity
    end

    test 'settings_reader, on the settable itself' do
      Account.settings_reader Account, %w[examples.cutoff_time]

      assert_equal '13:00', @account.cutoff_time
    ensure
      Account.remove_method(:cutoff_time)
    end

    test 'settings_reader of a setting no topic defines' do
      assert_raises(UnknownSetting) { Class.new { include Vario::SettingsReader }.settings_reader(Account, %w[examples.nothing]) }
    end

    test 'settings_reader before the topics are loaded defines its readers when they are' do
      loaded = Topic.instance_variable_get(:@loaded)
      Topic.instance_variable_set(:@loaded, false)
      reader = Class.new { include Vario::SettingsReader }
      reader.settings_reader(Account, %w[examples.enabled])
      refute reader.method_defined?(:enabled?)

      Topic.load!
      assert reader.method_defined?(:enabled?)
    ensure
      Topic.instance_variable_set(:@loaded, loaded)
    end
  end
end
