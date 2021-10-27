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
        config.setting 'setting3', keys: %i[name number]
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

    test 'group_name returns the group name based on dot notation' do
      setting = Setting.new
      setting.name = 'my_own.special.setting'
      assert_equal 'my_own', setting.group_name

      setting = Setting.new
      setting.name = 'setting'
      assert_nil setting.group_name

      setting = Setting.new
      assert_nil setting.group_name
    end

    test 'setting_name returns the setting name based on dot notation' do
      setting = Setting.new
      setting.name = 'my_own.special.setting'
      assert_equal 'special.setting', setting.setting_name

      setting = Setting.new
      setting.name = 'setting'
      assert_equal 'setting', setting.setting_name

      setting = Setting.new
      assert_nil setting.setting_name
    end

    test 'title returns a humanized title' do
      setting = Setting.new
      setting.name = 'my_own.special.setting'
      assert_equal 'My own: Special.setting', setting.title

      setting = Setting.new
      setting.name = 'setting'
      assert_equal 'Setting', setting.title

      setting = Setting.new
      assert_nil setting.title
    end

    test 'new_level gives a new level instance' do
      setting = Setting.new
      level   = setting.new_level

      assert_instance_of Level, level
      assert_same level.setting, setting
    end

    test 'cannot have multiple levels with the same conditions' do
      setting = Setting.new(name: 'setting3')
      first_level = setting.new_level
      first_level.conditions = { name: 'Tom', number: '(513) 736-7069 x0026' }
      first_level.value = '1'

      second_level = setting.new_level
      second_level.conditions = { name: 'Tom', number: '(513) 736-7069 x0026' }
      second_level.value = '2'

      setting.levels.unshift first_level
      assert setting.valid?

      setting.levels.unshift second_level
      refute setting.valid?
      assert_equal ['has already been taken'], setting.errors[:levels]

      second_level.conditions = { name: 'Piet', number: '(513) 736-7069 x0026' }
      assert setting.valid?
    end

    test 'uniq_levels returns unique levels based on keys' do
      setting = Setting.new(name: 'setting3',
                            levels: [{ conditions: { name: 'Tom',
                                                     number: '(513) 736-7069 x0026' }, value: 1 },
                                     { conditions: { name: 'Piet',
                                                     number: '(513) 736-7069 x0026' }, value: 3 },
                                     { conditions: { name: 'Tom',
                                                     number: '(513) 736-7069 x0026' }, value: 2 }])

      levels = setting.uniq_levels
      assert_equal 2, levels.size

      level = levels[0]
      assert_equal({ name: 'Tom', number: '(513) 736-7069 x0026' }, level.conditions_hash)
      assert_equal 1, level.value

      level = levels[1]
      assert_equal({ name: 'Piet', number: '(513) 736-7069 x0026' }, level.conditions_hash)
      assert_equal 3, level.value
    end

    test 'uniq_levels! updates setting with unique levels based on keys' do
      setting = Setting.new(name: 'setting3',
                            levels: [{ conditions: { name: 'Tom',
                                                     number: '(513) 736-7069 x0026' }, value: 1 },
                                     { conditions: { name: 'Piet',
                                                     number: '(513) 736-7069 x0026' }, value: 3 },
                                     { conditions: { name: 'Tom',
                                                     number: '(513) 736-7069 x0026' }, value: 2 }])

      setting.uniq_levels!

      setting = setting.reload
      levels = setting.levels
      assert_equal 2, levels.size

      level = levels[0]
      assert_equal({ name: 'Tom', number: '(513) 736-7069 x0026' }, level.conditions_hash)
      assert_equal 1, level.value

      level = levels[1]
      assert_equal({ name: 'Piet', number: '(513) 736-7069 x0026' }, level.conditions_hash)
      assert_equal 3, level.value
    end
  end
end
