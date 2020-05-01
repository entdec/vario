require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'there are two accounts' do
    assert_equal 2, Account.count
  end

  test 'is settable' do
    assert Account.included_modules.include?(Vario::Settable)
    assert accounts(:boxture).respond_to?(:setting)
    assert accounts(:boxture).respond_to?(:settings_hash)
  end
end
