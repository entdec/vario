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
      # Searchable: a link to each setting's section, under its topic
      assert_select "[data-vario--search-target=setting][data-keywords^='Working days'] a[href$='#setting_working_days']", text: 'Working days'
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

    def rule(variable, value, operator: 'is')
      { 'match' => 'all', 'rules' => { '0' => { 'variable' => variable, 'operator' => operator, 'value' => value } } }
    end

    test "a setting's refinements, a line each until opened, and one to add" do
      apple = products(:apple)
      @account.settings.create!(name: 'examples.quantity', value: 3, refinements_attributes: [
        { value: 10, conditions: { match: 'all', rules: [{ variable: 'product', operator: 'is', value: apple.id }, { variable: 'environment', operator: 'is', value: 'test' }] } },
        { value: 20, enabled: false, conditions: { match: 'any', rules: [] } }
      ])

      get path('examples')

      assert_select 'fieldset#setting_quantity .vario-refinements' do
        assert_select '.vario-refinements__head', text: /Refinements \(2\)/
        assert_select ".vario-refinement[data-new-record='false']", count: 2
        assert_select '.vario-refinement__summary', text: 'Product is Apple and Environment is test → 10'
        assert_select '.vario-refinement__summary', text: 'Always → 20'
        assert_select 'input[name="settings[quantity][refinements_attributes][0][position]"][value="1"]'
        assert_select 'input[type=checkbox][name="settings[quantity][refinements_attributes][1][enabled]"]:not([checked])'
        assert_select "input[name='settings[quantity][refinements_attributes][0][conditions][rules][0][variable]'][value='product']"
        assert_select "select[name='settings[quantity][refinements_attributes][0][conditions][rules][0][value]'] option[selected][value='#{apple.id}']", text: 'Apple'
        assert_select 'input[type=number][name="settings[quantity][refinements_attributes][0][value]"][value="10"]'
        assert_select "template input[name='settings[quantity][refinements_attributes][NEW_REFINEMENT][position]']"
        assert_select ".entdec-conditions[data-entdec--conditions-records-url-value*='records?']"
      end
    end

    test "the variables a setting's refinements can look at, and an object's records" do
      get "/settings/topics/examples/variables?settable=#{CGI.escape(@settable)}&setting=quantity&path="
      assert_equal [%w[environment string], %w[product object]], response.parsed_body['variables'].map { |variable| variable.values_at('name', 'type') }

      get "/settings/topics/examples/records?settable=#{CGI.escape(@settable)}&setting=quantity&path=product"
      assert_equal %w[Apple Lemon Orange], response.parsed_body['records'].map { |record| record['label'] }.sort

      get "/settings/topics/examples/records?settable=#{CGI.escape(@settable)}&setting=quantity&path=environment"
      assert_response :not_found
      get "/settings/topics/examples/variables?settable=#{CGI.escape(@settable)}&setting=nothing&path="
      assert_response :not_found
    end

    test 'saving refinements: new ones, in their order, and changed, disabled and removed ones' do
      apple = products(:apple)
      save(quantity: { value: '3', refinements_attributes: {
        '1' => { position: '1', enabled: '1', value: '10', conditions: rule('product', apple.id) },
        '2' => { position: '2', enabled: '1', value: '20', conditions: rule('environment', 'test') }
      } })
      setting = @account.settings.find_by(name: 'examples.quantity')
      first, second = setting.refinements

      assert_equal [[1, 10, [['product', 'is', apple.id]]], [2, 20, [%w[environment is test]]]],
                   setting.refinements.map { |refinement| [refinement.position, refinement.value, refinement.conditions['rules'].map { |rule| rule.values_at('variable', 'operator', 'value') }] }
      assert_equal 10, @account.reload.setting('examples.quantity', product: apple)

      # The second first, the first disabled; then removed
      save(quantity: { value: '3', refinements_attributes: {
        '0' => { id: second.id, position: '1', enabled: '1', value: '20' },
        '1' => { id: first.id, position: '2', enabled: '0', value: '10' }
      } })
      assert_equal [[second.id, 1, true], [first.id, 2, false]], setting.refinements.reload.map { |refinement| [refinement.id, refinement.position, refinement.enabled] }
      assert_equal 20, @account.reload.setting('examples.quantity', product: apple)

      save(quantity: { value: '3', refinements_attributes: { '0' => { id: second.id, _destroy: '1' }, '1' => { id: first.id, position: '1' } } })
      assert_equal [[first.id, 1]], setting.refinements.reload.map { |refinement| [refinement.id, refinement.position] }
    end

    test 'a rule without a variable is no rule' do
      save(quantity: { refinements_attributes: { '1' => { position: '1', value: '10', conditions: { 'match' => 'any', 'rules' => { '0' => { 'variable' => '', 'operator' => 'is' } } } } } })

      assert_equal({ 'match' => 'any', 'rules' => [] }, @account.settings.find_by(name: 'examples.quantity').refinements.first.conditions)
    end

    test 'what applies: every setting in the chosen context, and why' do
      apple = products(:apple)
      @account.settings.create!(name: 'examples.quantity', value: 3, refinements_attributes: [
        { value: 5, enabled: false, conditions: { match: 'all', rules: [{ variable: 'product', operator: 'is', value: apple.id }] } },
        { value: 10, conditions: { match: 'all', rules: [{ variable: 'product', operator: 'is', value: apple.id }] } }
      ])
      @account.settings.create!(name: 'examples.name', value: 'Boxture')

      get path('examples')
      assert_select '#applies select[name="applies[product]"] option', text: 'Apple'
      assert_select '#applies input[name="applies[environment]"]'
      assert_select '.vario-applies__table', count: 0

      get path('examples') + "&applies[product]=#{apple.id}&applies[environment]="

      assert_select '#applies select[name="applies[product]"] option[selected]', text: 'Apple'
      rows = css_select('.vario-applies__table tbody tr').to_h { |row| [row.at('th').text, row.css('td').map { |cell| cell.text.strip }] }
      assert_equal ['10', 'Refinement 2 (Product is Apple)'], rows['Quantity']
      assert_equal ['Boxture', 'Its own value'], rows['Name']
      assert_equal ['13:00', 'The default'], rows['Cutoff time']
      assert_equal ['Nothing', 'The default'], rows['Price']
    end

    test 'an unknown settable' do
      @settable = 'nothing'
      get path('examples')

      assert_response :not_found
    end
  end
end
