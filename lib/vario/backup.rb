# frozen_string_literal: true

module Vario
  # All settings and their refinements in a JSON file, and back, exactly as
  # they were, so the migration can run again from the same data:
  #
  #   bin/rails vario:backup FILE=vario_backup.json    # before vario:migrate
  #   bin/rails vario:restore FILE=vario_backup.json   # all settings as then
  #
  # The rows are read and written as stored, without the models (whose
  # callbacks change them), and restoring replaces every setting: those
  # added since go, those removed since come back, changes since are lost.
  class Backup
    VERSION = 1
    TABLES = { 'settings' => -> { Setting }, 'refinements' => -> { Refinement } }.freeze

    # The rows' counts by table
    def self.write(path)
      data = TABLES.transform_values { |model| rows(model.call) }
      File.write(path, JSON.pretty_generate({ 'vario_backup' => VERSION, 'created_at' => Time.current.iso8601, **data }))
      data.transform_values(&:size)
    end

    # The rows' counts by table, before and after
    def self.restore(path)
      data = JSON.parse(File.read(path))
      raise ArgumentError, "#{path} isn't a vario backup (version #{VERSION})" unless data['vario_backup'] == VERSION

      before = TABLES.transform_values { |model| model.call.count }
      ActiveRecord::Base.transaction do
        Refinement.delete_all
        Setting.delete_all
        TABLES.each do |table, model|
          columns = model.call.column_names
          data.fetch(table).each_slice(1000) { |rows| model.call.insert_all(rows.map { |row| row.slice(*columns) }) }
        end
      end

      { before: before, after: TABLES.transform_values { |model| model.call.count } }
    end

    # As stored: json as its data, arrays as arrays, times to the microsecond
    def self.rows(model)
      result = model.connection.select_all(model.unscoped.order(:id).to_sql)
      result.cast_values.map do |values|
        result.columns.zip(values).to_h { |column, value| [column, value.is_a?(Time) ? value.utc.iso8601(6) : value] }
      end
    end
  end
end
