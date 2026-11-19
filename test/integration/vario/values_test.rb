# frozen_string_literal: true

require 'test_helper'

module Vario
  # Settings on a page of the host's (render_vario_settings)
  class ValuesTest < ActionDispatch::IntegrationTest
    setup do
      @account = accounts(:boxture)
      @apple = products(:apple)
      @settable = @account.to_sgid(for: 'Vario').to_s
    end

    def save(values, context: {})
      patch '/settings/values', params: { settable: @settable, context: Vario.verifier.generate(context), values: values },
                                headers: { 'Referer' => "http://www.example.com/accounts/#{@account.id}" }
    end

    test 'its own values, and those on exactly a context' do
      @account.settings.create!(name: 'examples.quantity', value: 3, refinements_attributes: [
        { value: 10, conditions: { match: 'all', rules: [{ variable: 'product', operator: 'is', value: @apple.id }] } },
        { value: 20, conditions: { match: 'all', rules: [{ variable: 'product', operator: 'is', value: @apple.id }, { variable: 'environment', operator: 'is', value: 'test' }] } }
      ])

      get "/accounts/#{@account.id}"

      assert_response :success
      assert_select 'form[action="/settings/values"]', count: 2
      assert_select 'select[name="values[hide_couriers][value]"]'
      assert_select 'input[name="values[print_node.api_key][value]"]'
      # For the apple: the refinement on exactly it
      assert_select 'input[type=number][name="values[examples.quantity][value]"][value="10"]'
      assert_select 'select[name="values[examples.enabled][value]"] option[selected]', count: 0
    end

    test 'saving: its own value, and the value on the context, then back' do
      save({ 'hide_couriers' => { value: 'false' } })
      assert_redirected_to "http://www.example.com/accounts/#{@account.id}"

      save({ 'examples.quantity' => { value: '10' } }, context: { 'product_id' => @apple.id })
      save({ 'examples.quantity' => { value: '11' } }, context: { 'product_id' => @apple.id })

      @account.reload
      assert_equal false, @account.setting('hide_couriers')
      setting = @account.settings.find_by(name: 'examples.quantity')
      assert_nil setting.value
      assert_equal [[11, [['product', 'is', @apple.id]]]], setting.refinements.map { |refinement| [refinement.value, refinement.conditions['rules'].map { |rule| rule.values_at('variable', 'operator', 'value') }] }

      save({ 'examples.quantity' => { value: '' } }, context: { 'product_id' => @apple.id })
      assert_empty setting.refinements.reload
    end

    test 'a context that was changed, or a setting a topic does not define' do
      patch '/settings/values', params: { settable: @settable, context: 'tampered', values: { 'hide_couriers' => { value: 'false' } } }
      assert_response :not_found

      assert_no_difference -> { Setting.count } do
        save({ 'nothing' => { value: '1' } })
      end
    end

    test 'a topic it may not change' do
      Object.const_set(:GeneralSettingsPolicy, Class.new(TopicPolicy) { def update? = false })

      save({ 'hide_couriers' => { value: 'false' } })
      assert_response :forbidden
    ensure
      Object.send(:remove_const, :GeneralSettingsPolicy)
    end

    test "rendering a setting with a key it doesn't take, or no setting" do
      view = ActionController::Base.new.view_context
      assert_raises(ArgumentError) { view.render_vario_settings(@account, 'hide_couriers', { product_id: @apple.id }) }
      assert_raises(UnknownSetting) { view.render_vario_settings(@account, 'nothing') }
    end
  end
end
