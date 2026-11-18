# frozen_string_literal: true

require 'test_helper'

module Vario
  class SettingsTest < ActionDispatch::IntegrationTest
    setup do
      @account = accounts(:boxture)
      @settable = @account.to_sgid(for: 'Vario').to_s
    end

    test 'the settings of a settable, a tab per group' do
      get "/vario/settings?settable=#{CGI.escape(@settable)}"

      assert_response :success
      assert_select '.vario-card__tab', text: 'Print node'
      assert_select '.vario-card__tab', text: 'Ungrouped'
      assert_select '.vario-table a', text: 'Api key'
      assert_select '.vario-table a', text: 'Hide couriers'
    end

    test 'a setting, with a form per level and one for a new level' do
      setting = @account.settings.create!(name: 'print_node.api_key', levels: [{ id: 'one', conditions: { environment: 'test' }, value: 'Secret' }])

      get "/vario/settings/#{setting.id}"

      assert_response :success
      assert_select '.vario-card__title', text: 'Print node: Api key'
      assert_select "form#level_one[action='/vario/settings/#{setting.id}/levels/one']" do
        assert_select "select[name='level[conditions][environment]'] option[selected][value='test']"
        assert_select "input[name='level[value]'][value='Secret']"
        assert_select "button[name='commit'][value='delete']"
      end
      assert_select "[data-vario--sortable-target='item'][data-url='/vario/settings/#{setting.id}/levels/one/move']"
      assert_select "form[action='/vario/settings/#{setting.id}/levels'] .vario-level__title", text: 'New level'
    end

    test 'a boolean setting as a switch' do
      setting = @account.settings.create!(name: 'hide_couriers', levels: [{ id: 'one', conditions: {}, value: false }])

      get "/vario/settings/#{setting.id}"

      assert_response :success
      assert_select "form#level_one input[type='checkbox'][role='switch'][name='level[value]']:not([checked])"
    end

    test 'the settings on a page of the app' do
      get "/accounts/#{@account.id}"

      assert_response :success
      assert_select '.vario-card__tab', text: 'Hide couriers'
      assert_select '.vario-card__tab', text: 'Print node: Api key'
    end

    test 'adding a level' do
      setting = @account.settings.create!(name: 'print_node.api_key', levels: [])

      post "/vario/settings/#{setting.id}/levels", params: { level: { value: 'Secret', conditions: { environment: 'production' } } }

      assert_redirected_to "/vario/settings/#{setting.id}"
      assert_equal 'Secret', @account.reload.setting('print_node.api_key', environment: 'production')
    end

    test 'changing a level goes back to the page it was changed on' do
      setting = @account.settings.create!(name: 'print_node.api_key', levels: [{ id: 'one', conditions: { environment: 'test' }, value: 'Secret' }])

      patch "/vario/settings/#{setting.id}/levels/one", params: { commit: 'save', level: { value: 'Other', conditions: { environment: 'test' } } }, headers: { 'Referer' => "http://www.example.com/accounts/#{@account.id}" }

      assert_redirected_to "http://www.example.com/accounts/#{@account.id}"
      assert_equal 'Other', @account.reload.setting('print_node.api_key', environment: 'test')
    end

    test 'deleting a level' do
      setting = @account.settings.create!(name: 'print_node.api_key', levels: [{ id: 'one', conditions: { environment: 'test' }, value: 'Secret' }])

      patch "/vario/settings/#{setting.id}/levels/one", params: { commit: 'delete', level: { value: 'Secret' } }

      assert_redirected_to "/vario/settings/#{setting.id}"
      assert_empty Setting.find(setting.id).levels
    end

    test 'moving a level' do
      setting = @account.settings.create!(name: 'print_node.api_key', levels: [{ id: 'one', conditions: { environment: 'test' }, value: 'A' },
                                                                                { id: 'two', conditions: { environment: 'production' }, value: 'B' }])

      patch "/vario/settings/#{setting.id}/levels/two/move", params: { index: 0 }, as: :json

      assert_response :success
      assert_equal %w[two one], Setting.find(setting.id).levels.map(&:id)
    end
  end
end
