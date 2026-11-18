# frozen_string_literal: true

require 'test_helper'

module Vario
  class RefinementTest < ActiveSupport::TestCase
    setup do
      @setting = accounts(:boxture).settings.create!(name: 'print_node.api_key')
    end

    test 'refinements are in order of their position, which positioning keeps from 1 without gaps' do
      first = @setting.refinements.create!(value: 'a')
      second = @setting.refinements.create!(value: 'b')
      third = @setting.refinements.create!(value: 'c')
      assert_equal [1, 2, 3], [first, second, third].map { |refinement| refinement.reload.position }

      third.update!(position: { before: first })
      assert_equal %w[c a b], @setting.refinements.reload.map(&:value)
      assert_equal [1, 2, 3], @setting.refinements.map(&:position)

      first.destroy!
      assert_equal [[1, 'c'], [2, 'b']], @setting.refinements.reload.map { |refinement| [refinement.position, refinement.value] }
    end

    test 'a setting and its refinements are saved together' do
      @setting.update!(value: 'default', refinements_attributes: [
        { value: 'test', conditions: { match: 'all', rules: [{ variable: 'environment', operator: 'is', value: 'test' }] } },
        { value: 'staging', enabled: false, note: 'Not yet' }
      ])

      setting = Setting.find(@setting.id)
      assert_equal 'default', setting.value
      assert_equal [[1, 'test', true], [2, 'staging', false]], setting.refinements.map { |refinement| [refinement.position, refinement.value, refinement.enabled] }
      assert_equal 'environment', setting.refinements.first.conditions.dig('rules', 0, 'variable')

      setting.update!(refinements_attributes: [{ id: setting.refinements.first.id, _destroy: '1' }])
      assert_equal %w[staging], Setting.find(@setting.id).refinements.map(&:value)
    end

    test 'jsonb keeps the type of a value no topic defines' do
      setting = accounts(:boxture).settings.create!(name: 'undefined.value')
      [true, false, 13, 2.5, '13:00', %w[1 2], { 'a' => 1 }].each do |value|
        setting.update!(value: value)
        refinement = setting.refinements.create!(value: value)

        assert_equal value, Setting.find(setting.id).value
        assert_equal value, Refinement.find(refinement.id).value
      end
    end

    test 'a refinement without conditions has none' do
      assert_equal({ 'match' => 'all', 'rules' => [] }, @setting.refinements.create!.conditions)
    end

    test 'a settable has a setting once' do
      assert_raises(ActiveRecord::RecordNotUnique) do
        accounts(:boxture).settings.create!(name: 'print_node.api_key')
      end
    end

    test 'refinements go with their setting' do
      refinement = @setting.refinements.create!(value: 'a')
      @setting.destroy!

      refute Refinement.exists?(refinement.id)
    end
  end
end
