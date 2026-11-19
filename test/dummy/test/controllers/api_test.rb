# frozen_string_literal: true

require 'test_helper'

class ApiTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  test 'get the hide_couriers setting' do
    get "/api/account_settings/#{accounts(:boxture).id}/hide_couriers"
    assert last_response.ok?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal true, last_json['value']
  end

  test 'include and before is respected' do
    get "/api/settings_with_one_include_and_before/#{accounts(:boxture).id}/hide_couriers"
    assert last_response.forbidden?
    assert_equal 'Access Denied', last_json['error']

    get "/api/settings_with_one_include_and_before/#{accounts(:boxture).id}/hide_couriers?api_key=ThisIsMyApiKey"
    assert last_response.ok?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal true, last_json['value']
  end

  test 'use prefix within the route' do
    get "/api/accounts/#{accounts(:boxture).id}/settings/hide_couriers"
    assert last_response.ok?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal true, last_json['value']
  end

  test 'set the hide_couriers setting' do
    post "/api/account_settings/#{accounts(:boxture).id}/hide_couriers", JSON.dump({ value: false }), { 'CONTENT_TYPE' => 'application/json' }
    assert last_response.created?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal false, last_json['value']

    get "/api/account_settings/#{accounts(:boxture).id}/hide_couriers"
    assert last_response.ok?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal false, last_json['value']
  end

  test 'delete removes hide_couriers setting' do
    post "/api/account_settings/#{accounts(:boxture).id}/hide_couriers", JSON.dump({ value: false }), { 'CONTENT_TYPE' => 'application/json' }
    assert last_response.created?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal false, last_json['value']

    delete "/api/account_settings/#{accounts(:boxture).id}/hide_couriers", JSON.dump({ value: false }), { 'CONTENT_TYPE' => 'application/json' }
    assert last_response.ok?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal true, last_json['value']

    get "/api/account_settings/#{accounts(:boxture).id}/hide_couriers"
    assert last_response.ok?
    assert_equal 'hide_couriers', last_json['setting']
    assert_equal true, last_json['value']
  end

  test 'setting and getting the print_node.api_key setting' do
    post "/api/account_settings/#{accounts(:boxture).id}/print_node/api_key", JSON.dump({ environment: 'test', value: 'ApiForYouApiForMe' }), { 'CONTENT_TYPE' => 'application/json' }
    assert last_response.created?
    assert_equal 'print_node.api_key', last_json['setting']
    assert_equal 'ApiForYouApiForMe', last_json['value']

    get "/api/account_settings/#{accounts(:boxture).id}/print_node/api_key?environment=production"
    assert last_response.ok?
    assert_equal 'print_node.api_key', last_json['setting']
    assert_nil last_json['value']

    get "/api/account_settings/#{accounts(:boxture).id}/print_node/api_key?environment=test"
    assert last_response.ok?
    assert_equal 'print_node.api_key', last_json['setting']
    assert_equal 'ApiForYouApiForMe', last_json['value']
  end

  test 'with keys, the value of the refinement on exactly those' do
    account = accounts(:boxture)
    product = products(:apple)
    url = "/api/account_settings/#{account.id}/examples/quantity"

    post url, JSON.dump({ product_id: product.id, value: 5 }), { 'CONTENT_TYPE' => 'application/json' }
    assert last_response.created?
    assert_equal 5, last_json['value']

    put url, JSON.dump({ product_id: product.id, value: 6 }), { 'CONTENT_TYPE' => 'application/json' }
    put url, JSON.dump({ product_id: product.id, environment: 'test', value: 7 }), { 'CONTENT_TYPE' => 'application/json' }

    setting = account.settings.find_by(name: 'examples.quantity')
    assert_nil setting.value
    assert_equal [[7, [%w[environment is test], ['product', 'is', product.id]]], [6, [['product', 'is', product.id]]]],
                 setting.refinements.map { |refinement| [refinement.value, refinement.conditions['rules'].map { |rule| rule.values_at('variable', 'operator', 'value') }.sort] }

    get url, product_id: product.id, environment: 'production'
    assert_equal 6, last_json['value']
    # The environment is Rails.env when it isn't given (config.context_default)
    get url, product_id: product.id
    assert_equal 7, last_json['value']
    get url, product_id: products(:orange).id, environment: 'production'
    assert_equal 1, last_json['value']

    delete url, product_id: product.id
    assert_equal 7, last_json['value']
    assert_equal [7], setting.refinements.reload.map(&:value)
  end

  test 'a value of the choices' do
    url = "/api/account_settings/#{accounts(:boxture).id}/examples/size"

    post url, JSON.dump({ value: 'huge' }), { 'CONTENT_TYPE' => 'application/json' }
    assert last_response.bad_request?

    post url, JSON.dump({ value: 'large' }), { 'CONTENT_TYPE' => 'application/json' }
    assert_equal 'large', last_json['value']
  end

  test 'keys a setting does not take are ignored' do
    post "/api/account_settings/#{accounts(:boxture).id}/hide_couriers", JSON.dump({ environment: 'test', value: false }), { 'CONTENT_TYPE' => 'application/json' }

    assert_equal false, last_json['value']
    assert_empty accounts(:boxture).settings.find_by(name: 'hide_couriers').refinements
  end

  test "the keys of a setting: its roots or their ids, and the legacy keys into them" do
    legacy_keys = Vario.config.legacy_keys.dup
    Vario.config.legacy_key :product_code, 'product.code'
    Vario.config.legacy_key :customer_id, 'order.customer'

    assert_equal %w[environment product_id product_code], Vario::Topic.definition(Account, 'examples.quantity').legacy_keys
    assert_equal [], Vario::Topic.definition(Account, 'hide_couriers').legacy_keys
  ensure
    Vario.config.legacy_keys.replace(legacy_keys)
  end

  def app
    Rails.application
  end

  def last_json
    HashWithIndifferentAccess.new JSON.parse(last_response.body)
  end
end
