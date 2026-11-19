# frozen_string_literal: true

require 'test_helper'
require 'rake'

module Vario
  class MigratorTest < ActiveSupport::TestCase
    setup do
      @boxture = accounts(:boxture)
      @skepr = accounts(:skepr)
      # 1.x's fixtures, without a settable
      Setting.where(settable_id: nil).delete_all
    end

    def row(settable, name, levels)
      id = Setting.insert!({ settable_type: settable.class.name, settable_id: settable.id, name: name, keys: %w[order_type], levels: levels }, returning: :id).first['id']
      Setting.find(id)
    end

    def rows
      row(@boxture, 'examples.quantity', [{ conditions: { order_type: 'SalesOrder' }, value: '9' }, { conditions: {}, value: '3' }, { conditions: { order_type: 'ReturnOrder' }, value: '7' }])
      row(@boxture, 'examples.enabled', [{ conditions: {}, value: 'off' }])
      row(@boxture, 'nothing.here', [{ conditions: {}, value: '1' }])
      row(@skepr, 'examples.quantity', [{ conditions: {}, value: '' }])
      row(@skepr, 'examples.name', [])
    end

    test 'the report, without changing anything' do
      rows
      report = nil

      assert_no_difference -> { Refinement.count } do
        report = Migrator.new.call
      end

      assert_nil Setting.find_by(name: 'examples.quantity', settable: @boxture)[:value]
      assert_equal({ settables: 2, converted: 3, dead: 1, empty: 1, uncastable: 1, unknown: 1, skipped: 0 }, report.totals)
      assert_equal <<~REPORT.chomp, report.to_s
        Account Boxture (#{@boxture.id})
          converted 2, dead 1, empty 0, already converted 0
          dead: examples.quantity (1)
          uncastable: examples.enabled "off"
          unknown: nothing.here

        Account Skepr (#{@skepr.id})
          converted 1, dead 0, empty 1, already converted 0

        Total: 2 settables, 3 settings converted, 1 dead levels, 1 empty, 1 uncastable, 1 unknown, 0 already converted
      REPORT
    end

    test 'migrating, then again: the converted ones are skipped' do
      rows
      Migrator.new.call(apply: true)

      assert_equal 3, @boxture.reload.setting('examples.quantity', order_type: 'ReturnOrder')
      assert_equal 9, @boxture.setting('examples.quantity', order_type: 'SalesOrder')

      @boxture.settings.find_by(name: 'examples.quantity').refinements.first.update!(value: 10)
      assert_equal 2, Migrator.new.call(apply: true).totals[:skipped]
      assert_equal 10, @boxture.reload.setting('examples.quantity', order_type: 'SalesOrder')
    end

    test 'forced, the converted ones again' do
      rows
      Migrator.new.call(apply: true)
      @boxture.settings.find_by(name: 'examples.quantity').refinements.first.update!(value: 10)

      assert_equal 0, Migrator.new(force: true).call(apply: true).totals[:skipped]
      assert_equal 9, @boxture.reload.setting('examples.quantity', order_type: 'SalesOrder')
    end

    test 'the tasks' do
      Rails.application.load_tasks if Rake::Task.tasks.empty?

      assert Rake::Task.task_defined?('vario:migrate')
      assert Rake::Task.task_defined?('vario:migrate:report')
    end
  end
end
