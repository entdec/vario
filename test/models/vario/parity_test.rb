# frozen_string_literal: true

require 'test_helper'

module Vario
  # 1.x settings, converted, read in 2.0 as 1.x read them (Vario1Resolver,
  # and while it's there 1.x's Setting#value_for)
  class ParityTest < ActiveSupport::TestCase
    CASES = YAML.safe_load(ERB.new(File.read(File.expand_path('../../fixtures/files/vario_1_parity.yml.erb', __dir__))).result)

    setup do
      @account = accounts(:boxture)
      @settable_settings = Vario.config.settable_settings['Account'].dup
      @legacy_keys = Vario.config.legacy_keys.dup
      Vario.config.legacy_key :customer_id, 'order.customer'
    end

    teardown do
      Vario.config.settable_settings['Account'] = @settable_settings
      Vario.config.legacy_keys.replace(@legacy_keys)
    end

    # As 1.x's callers did: every key, nil without a value
    def context_for(example, context)
      example['keys'].to_h { |key| [key, nil] }.merge(context)
    end

    CASES.each_with_index do |example, index|
      test "#{example['name']} #{example['description'] || index}" do
        options = example.slice('type', 'keys', 'default', 'collection').symbolize_keys
        options[:type] = options[:type].to_sym
        Vario.config.setting(example['name'], **options, settable_type: 'Account')
        # As the rows are, whether 1.x would save them or not
        id = Setting.insert!({ settable_type: 'Account', settable_id: @account.id, name: example['name'], keys: example['keys'], levels: example['levels'] }, returning: :id).first['id']

        # The default as 1.x's config kept it (options[:default] ||= nil: no false)
        default = Vario.config.settable_setting('Account', example['name'])[:default]
        frozen = example['contexts'].map do |context|
          Vario1Resolver.value_for(levels: example['levels'], keys: example['keys'], type: options[:type], default: default,
                                   collection: example['collection'], context: context_for(example, context), value_procs: { environment: -> { Rails.env } })
        end
        assert_equal frozen, example['contexts'].map { |context| Setting.find(id).value_for(context_for(example, context).symbolize_keys) }, 'the frozen resolver reads as 1.x'

        Converter.new(Setting.find(id)).call.apply!
        @account.reload

        example['contexts'].zip(frozen).each do |context, value|
          read = @account.setting(example['name'], context_for(example, context).symbolize_keys)
          # Where 1.x had nil for a boolean (its false default), 2.0 has false
          read = nil if options[:type] == :boolean && value.nil? && read == false
          value.nil? ? assert_nil(read, "#{example['name']} in #{context.inspect}") : assert_equal(value, read, "#{example['name']} in #{context.inspect}")
        end
      end
    end
  end
end
