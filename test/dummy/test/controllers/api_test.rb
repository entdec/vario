# frozen_literal_string: true

require 'test_helper'

class ApiTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  test 'get the hide_couriers setting' do
    get "/api/account_settings/#{accounts(:boxture).id}/hide_couriers"
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

  def app
    Rails.application
  end

  def last_json
    HashWithIndifferentAccess.new JSON.parse(last_response.body)
  end
end
