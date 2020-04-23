# frozen_string_literal: true

require 'test_helper'
require 'vario'

module Vario
  class SettingTest < ActiveSupport::TestCase
    setup do
      Vario.setup do |config|
        config.setting 'test'
        config.setting 'setting1'
        config.setting 'setting2'
      end
    end

    test 'can store a setting' do
      setting = Setting.new(name: 'test', levels: [conditions: {}, value: 1])
      assert setting.valid?, setting.errors.full_messages
    end

    test 'can retrieve a setting' do
      assert_equal 1, Setting.where(name: 'setting1').first.value_for(key: nil)
    end

    test 'can change a setting' do
      setting = Setting.where(name: 'setting1').first
      setting.levels.first.value = 3
      assert_equal 3, setting.value_for(key: nil)
    end

    test 'can change and save a setting' do
      setting = Setting.where(name: 'setting1').first
      setting.levels.first.value = 5
      setting.save
      setting = Setting.where(name: 'setting1').first
      assert_equal 5, setting.value_for(key: nil)
    end
  end
end
