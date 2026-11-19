# frozen_string_literal: true

require 'test_helper'

module Vario
  class BackupTest < ActiveSupport::TestCase
    setup do
      @boxture = accounts(:boxture)
      @skepr = accounts(:skepr)
      @path = Rails.root.join('tmp', "vario_backup_test_#{SecureRandom.hex(4)}.json").to_s
    end

    teardown do
      FileUtils.rm_f(@path)
    end

    def row(settable, name, levels, value: nil)
      Setting.insert!({ settable_type: settable.class.name, settable_id: settable.id, name: name, keys: %w[order_type], levels: levels, value: value },
                      returning: :id).first['id']
    end

    # Every column of both tables, as the database gives them
    def stored
      Backup::TABLES.transform_values { |model| model.call.connection.select_rows("SELECT * FROM #{model.call.table_name} ORDER BY id") }
    end

    test 'restored exactly as backed up, after migrating, changing, adding and removing' do
      row(@boxture, 'examples.quantity', [{ conditions: { order_type: 'SalesOrder' }, value: '9' }, { conditions: {}, value: '3' }])
      removed = row(@boxture, 'examples.enabled', [{ conditions: {}, value: '1' }])
      row(@skepr, 'examples.name', [], value: 'Skepr')
      refined = Setting.find(row(@skepr, 'examples.size', nil, value: 'small'))
      refined.refinements.create!(position: 1, note: 'As it was', conditions: { match: 'all', rules: [{ variable: 'order_type', operator: 'is', value: 'SalesOrder' }] }, value: 'large')
      backed_up = stored

      assert_equal({ 'settings' => Setting.count, 'refinements' => 1 }, Backup.write(@path))

      Migrator.new.call(apply: true)
      Setting.find(removed).destroy!
      refined.refinements.first.update!(value: 'medium')
      @boxture.settings.create!(name: 'examples.notes', value: 'New')
      assert_not_equal backed_up, stored

      counts = Backup.restore(@path)

      assert_equal backed_up, stored
      assert_equal({ 'settings' => Setting.count, 'refinements' => 1 }, counts[:after])
      # And the migration runs again as the first time
      assert_equal 9, Migrator.new.call(apply: true).then { @boxture.setting('examples.quantity', order_type: 'SalesOrder', environment: 'production') }
    end

    test "a file that isn't a backup changes nothing" do
      row(@boxture, 'examples.quantity', [{ conditions: {}, value: '3' }])
      File.write(@path, { settings: [] }.to_json)

      assert_no_difference -> { Setting.count } do
        assert_raises(ArgumentError) { Backup.restore(@path) }
      end
    end
  end
end
