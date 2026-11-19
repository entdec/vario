# frozen_string_literal: true

require 'test_helper'

module Vario
  class TopicsTest < ActionDispatch::IntegrationTest
    # Hidden from everyone, and one that can be seen but not changed
    setup do
      @account = accounts(:boxture)
      @settable = @account.to_sgid(for: 'Vario').to_s

      Object.const_set(:GeneralSettingsPolicy, Class.new(TopicPolicy) { def show? = false })
      Object.const_set(:PrintNodeSettingsPolicy, Class.new(TopicPolicy) { def update? = false })
    end

    teardown do
      Object.send(:remove_const, :GeneralSettingsPolicy)
      Object.send(:remove_const, :PrintNodeSettingsPolicy)
    end

    def path(key = nil)
      ["/settings/topics", key].compact.join('/') + "?settable=#{CGI.escape(@settable)}"
    end

    def save(settings)
      patch path('examples'), params: { settings: settings }
    end

    test 'the topics, the first by title' do
      get path

      assert_redirected_to path('examples')
    end

    test 'a topic: the topics it may see, and a section per setting with its own value' do
      @account.settings.create!(name: 'examples.quantity', value: 3)

      get path('examples')

      assert_response :success
      assert_select '.vario-topics__link', count: 2
      assert_select ".vario-topics__link[aria-current='page']", text: 'Examples'
      assert_select '.vario-topics__link', text: 'PrintNode'
      assert_select 'fieldset.vario-setting', count: ExamplesSettings.definitions.size
      assert_select 'fieldset#setting_quantity input[type=number][name="settings[quantity][value]"][value="3"]'
      assert_select 'fieldset#setting_quantity', text: /Default: 1/
      assert_select 'fieldset#setting_enabled select[name="settings[enabled][value]"]' do
        assert_select 'option[selected]', count: 0
        assert_select 'option:first-child[value=""]', text: 'Default'
      end
      assert_select 'fieldset#setting_cutoff_time input[type=time][name="settings[cutoff_time][value]"]'
      assert_select 'fieldset#setting_notes textarea[name="settings[notes][value]"]'
      assert_select 'fieldset#setting_working_days input[type=checkbox][name="settings[working_days][value][]"]', count: 7
      assert_select 'fieldset#setting_size select[name="settings[size][value]"] option[value="medium"]'
      assert_select 'fieldset#setting_owner select[name="settings[owner][value]"] option', text: 'Skepr'
      assert_select 'fieldset#setting_working_days', text: /Default: Monday, Tuesday, Wednesday, Thursday, Friday/
    end

    test 'saving: the values as their types, only the settings that have one' do
      assert_difference -> { @account.settings.count }, 4 do
        save(quantity: { value: '13' }, enabled: { value: 'false' }, working_days: { value: ['', '1', '3'] }, options: { value: "a: 1\n" },
             name: { value: '' }, size: { value: '' })
      end

      assert_redirected_to path('examples')
      @account.reload
      assert_equal [13, false, %w[1 3], { 'a' => 1 }], %w[quantity enabled working_days options].map { |key| @account.setting("examples.#{key}") }
    end

    test 'saving nothing clears a value, so the default applies' do
      @account.settings.create!(name: 'examples.quantity', value: 3)

      save(quantity: { value: '' })

      assert_nil @account.settings.find_by(name: 'examples.quantity')[:value]
      assert_equal 1, @account.reload.setting('examples.quantity')
    end

    test "keys of other topics' or no settings are left alone" do
      assert_no_difference -> { Setting.count } do
        save(nothing: { value: '1' }, api_key: { value: 'x' })
      end
    end

    test 'a topic it may not see, or change' do
      get path('general')
      assert_response :not_found

      patch path('print_node'), params: { settings: { api_key: { value: 'x' } } }
      assert_response :forbidden
      assert_nil @account.settings.find_by(name: 'print_node.api_key')
    end

    test 'an unknown settable' do
      @settable = 'nothing'
      get path('examples')

      assert_response :not_found
    end
  end
end
