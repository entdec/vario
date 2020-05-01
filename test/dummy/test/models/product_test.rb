require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  test 'there are three products' do
    assert_equal 3, Product.count
  end

  test 'is not settable' do
    refute Product.included_modules.include?(Vario::Settable)
    refute products(:apple).respond_to?(:setting)
    refute products(:apple).respond_to?(:settings_hash)
  end
end
