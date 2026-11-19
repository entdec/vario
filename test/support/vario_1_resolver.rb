# frozen_string_literal: true

# Vario 1.x's Setting#value_for, frozen for the parity suite, so it stays
# when 1.x's levels go: a setting's levels in order, the first whose
# conditions (of the setting's keys, those with a value) the context has
# gives the value, else the default.
module Vario1Resolver
  module_function

  # value_procs: 1.x's config.key value_proc, filling keys the context has no value for
  def value_for(levels:, keys:, type: :string, default: nil, collection: nil, context: {}, value_procs: {})
    context = context.symbolize_keys
    current_default = context.delete(:default)
    keys = keys.map(&:to_sym)

    keys.each do |key|
      context[key] ||= value_procs[key].call if value_procs.key?(key)
    end
    missing = keys - context.keys
    raise ArgumentError, "missing context '#{missing.join(', ')}''" if missing.present?

    result = levels.map { |level| level.to_h.with_indifferent_access }.find do |level|
      context >= conditions_hash(level, keys)
    end

    return parse_value(result[:value], type, collection) if result && (result[:value] === false || result[:value].present?)

    parse_value(current_default || default, type, collection)
  end

  def conditions_hash(level, keys)
    conditions = (level[:conditions] || {}).with_indifferent_access
    keys.map { |key| [key, conditions[key]] }.reject { |_key, value| value.blank? }.to_h
  end

  def parse_value(value, type, collection)
    return false if [0, '0', 'false', '', false].include?(value) && type == :boolean
    return true if [1, '1', 'true', true].include?(value) && type == :boolean
    return unless value.present?
    return parse_value_array(value, collection) if type == :array
    return value unless value.is_a?(String)
    return YAML.load(value) if type == :hash
    return value.to_i if type == :integer

    value
  end

  def parse_value_array(value, collection)
    values = value
    values = values.split(/,|\n/).map(&:strip) if values.is_a?(String)
    values = values.reject(&:blank?)
    return collection.map(&:last) if (values.include?('all') || values.include?(:all)) && collection

    values
  end
end
