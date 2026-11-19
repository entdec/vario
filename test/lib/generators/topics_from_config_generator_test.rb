# frozen_string_literal: true

require 'test_helper'
require 'generators/vario/topics_from_config/topics_from_config_generator'

module Vario
  class TopicsFromConfigGeneratorTest < Rails::Generators::TestCase
    tests Vario::Generators::TopicsFromConfigGenerator
    destination File.expand_path('../../dummy/tmp/generators', __dir__)
    setup :prepare_destination

    setup do
      @config = Vario.config
      Vario.setup do |config|
        config.key :user_id, name: 'User', type: :select, value_proc: -> { nil }
        config.key :environment, name: 'Environment', type: :select, value_proc: -> { Rails.env }
        config.key :export, name: 'Export?', type: :boolean

        config.for_settable_type 'Account' do |settable|
          settable.show_group_if 'modules', -> { true }
          settable.setting 'shipping.cutoff_time', type: :string, default: '13:00', keys: %i[account_id order_type], description: 'Latest time.'
          settable.setting 'shipping.sla_days', type: :integer, default: 0, keys: %i[order_type]
          settable.setting 'shipping.size', type: :string, keys: %i[account_id order_type export], collection_proc: -> { [%w[Small small], %w[Large large]] }
          settable.setting 'shipping.owner', type: :string, keys: %i[account_id order_type export], collection_proc: -> { Account.where(id: @setting.settable).map { |a| [a.name, a.id] } }
          settable.setting 'shipping.week_start', type: :symbol, default: :monday, collection: [['Monday', :monday], ['Sunday', :sunday]]
          settable.setting 'shipping.working_days', type: :array, default: %w[1 2], collection: [['Monday', 1], ['Tuesday', 2]], keys: %i[environment]
          settable.setting 'shipping.note', type: :string, default: ''
          settable.setting 'shipping.copy_from', type: :string, collection_proc: -> { Account.order(:name).map { |a| [a.name, a.id] } }
          settable.setting 'shipping.location', type: :string, keys: %i[location_id]
          settable.setting 'hide_couriers', type: :boolean, default: true
        end

        config.for_settable_type 'Product' do |settable|
          settable.setting 'shipping.reorder_level', type: :integer, default: 0
        end
      end
    end

    teardown do
      Vario.instance_variable_set(:@config, @config)
    end

    test 'a topic per group, its context the keys its settings use' do
      run_generator

      assert_file 'app/settings/shipping_settings.rb', <<~RUBY
        # frozen_string_literal: true

        class ShippingSettings < Vario::Topic
          settable Account
          context account: Account, order_type: :string, export: :boolean, environment: :string, location_id: :string

          setting :cutoff_time, :time, default: "13:00", context: %i[account order_type]
          setting :sla_days, :integer, default: 0, context: %i[order_type]
          setting :size, :string, choices: -> { [%w[Small small], %w[Large large]] }, context: %i[account order_type export]
          # TODO: choices, from 1.x's collection_proc: -> { Account.where(id: @setting.settable).map { |a| [a.name, a.id] } }
          setting :owner, :string, context: %i[account order_type export]
          setting :week_start, :string, default: "monday", choices: [["Monday", "monday"], ["Sunday", "sunday"]], context: %i[]
          setting :working_days, :array, default: ["1", "2"], choices: [["Monday", "1"], ["Tuesday", "2"]], context: %i[environment]
          setting :note, :string, context: %i[]
          # TODO: Account records? setting :x, Account
          setting :copy_from, :string, choices: -> { Account.order(:name).map { |a| [a.name, a.id] } }, context: %i[]
          setting :location, :string, context: %i[location_id]
        end
      RUBY
      assert_file 'app/settings/general_settings.rb', /setting :hide_couriers, :boolean, default: true, name: 'hide_couriers'/
      assert_file 'app/settings/product_shipping_settings.rb', /class ProductShippingSettings < Vario::Topic\n  settable Product\n  key 'shipping'\n\n  setting :reorder_level, :integer, default: 0\nend/
    end

    test 'the texts, from the descriptions' do
      run_generator %w[--locale=en]

      assert_file 'config/locales/vario.en.yml' do |content|
        texts = YAML.safe_load(content).dig('en', 'vario', 'topics')
        assert_equal({ 'label' => 'Cutoff time', 'description' => 'Latest time.' }, texts.dig('shipping', 'settings', 'cutoff_time'))
        assert_equal({ 'label' => 'Sla days' }, texts.dig('shipping', 'settings', 'sla_days'))
        assert_equal 'Shipping', texts.dig('shipping', 'title')
      end
    end

    test 'notes on what it leaves to do' do
      output = run_generator

      assert_match(/environment had a value_proc: add config.context_default :environment/, output)
      assert_no_match(/user_id had a value_proc/, output)
      assert_match(/modules had show_group_if: add a ModulesSettingsPolicy/, output)
      assert_match(/TODOs left in the topics/, output)
    end

    test 'the topics it writes load, and read' do
      run_generator
      source = File.read(File.join(destination_root, 'app/settings/shipping_settings.rb')).sub('class ShippingSettings', 'class GeneratedShippingSettings').sub("  settable Account\n", "  settable Account\n  key 'generated_shipping'\n")
      Object.class_eval(source)

      assert_equal '13:00', accounts(:boxture).setting('generated_shipping.cutoff_time')
      assert_equal %w[small large], Topic.definition(Account, 'generated_shipping.size').choice_values
    ensure
      Topic.registered.delete(GeneratedShippingSettings) if defined?(GeneratedShippingSettings)
      Object.send(:remove_const, :GeneratedShippingSettings) if defined?(GeneratedShippingSettings)
    end
  end
end
