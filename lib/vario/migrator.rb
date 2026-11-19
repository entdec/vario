# frozen_string_literal: true

module Vario
  # Converts the 1.x settings (their levels) of all settables, or reports
  # what that would do (Converter):
  #
  #   bin/rails vario:migrate:report   # what it would do, per settable
  #   bin/rails vario:migrate          # do it
  #
  # Settings already converted (with a value or refinements) are skipped, so
  # it can run again; FORCE=1 converts them again, which discards what was
  # changed in 2.0 since.
  class Migrator
    def initialize(force: false)
      @force = force
    end

    # The report, applied or not
    def call(apply: false)
      report = Report.new

      Setting.where.not(levels: nil).includes(:settable, :refinements).find_each do |setting|
        # Nothing to convert (1.x's create_on_request rows, 2.0's)
        next if setting.attributes['levels'].blank?

        if !@force && (!setting[:value].nil? || setting.refinements.any?)
          report.add(setting, nil)
          next
        end

        conversion = Converter.new(setting).call
        conversion.apply! if apply && !conversion.unknown?
        report.add(setting, conversion)
      end

      report
    end
  end

  # What the migration did or would do, per settable
  class Report
    Line = Data.define(:name, :conversion)

    def initialize
      @lines = Hash.new { |hash, settable| hash[settable] = [] }
    end

    # conversion is nil for a setting already converted
    def add(setting, conversion)
      @lines[[setting.settable_type, setting.settable_id, setting.settable]] << Line.new(name: setting.name, conversion: conversion)
    end

    def totals
      lines = @lines.values.flatten
      conversions = lines.filter_map(&:conversion)
      known = conversions.reject(&:unknown?)

      { settables: @lines.size, converted: known.size, dead: known.sum(&:dead), empty: known.sum(&:empty),
        uncastable: known.sum { |conversion| conversion.uncastable.size }, unknown: conversions.count(&:unknown?), skipped: lines.count { |line| line.conversion.nil? } }
    end

    def to_s
      output = @lines.sort_by { |(type, id, settable), _lines| [type.to_s, settable.try(:name).to_s, id.to_s] }.map do |(type, id, settable), lines|
        title = [type, settable.try(:name), id && "(#{id})"].compact.join(' ')
        conversions = lines.select(&:conversion)
        known = conversions.reject { |line| line.conversion.unknown? }

        [
          title,
          "  converted #{known.size}, dead #{known.sum { |line| line.conversion.dead }}, empty #{known.sum { |line| line.conversion.empty }}, already converted #{lines.size - conversions.size}",
          *known.select { |line| line.conversion.dead.positive? }.map { |line| "  dead: #{line.name} (#{line.conversion.dead})" },
          *known.flat_map { |line| line.conversion.uncastable.map { |value| "  uncastable: #{line.name} #{value.inspect}" } },
          *conversions.select { |line| line.conversion.unknown? }.map { |line| "  unknown: #{line.name}" }
        ].join("\n")
      end

      totals = self.totals
      output << "Total: #{totals[:settables]} settables, #{totals[:converted]} settings converted, #{totals[:dead]} dead levels, " \
                "#{totals[:empty]} empty, #{totals[:uncastable]} uncastable, #{totals[:unknown]} unknown, #{totals[:skipped]} already converted"
      output.join("\n\n")
    end
  end
end
