# frozen_string_literal: true

module Vario
  # What a setting of a settable is in a context, and why: the first enabled
  # refinement (by position) whose conditions are met, else the settable's own
  # value, else the default (given when it's read, else the definition's).
  #
  #   Resolver.new(account).explain('shipping.cutoff_time', order: order)
  #   # => #<Vario::Resolution value="15:00", source=:refinement, refinement=...>
  class Resolver
    def initialize(settable, settings)
      @settable = settable
      @settings = settings
    end

    def explain(name, context = {})
      name = name.to_s
      definition = Topic.definition(@settable, name)
      raise UnknownSetting, "Setting '#{name}' is not defined for #{@settable.class.name}" unless definition

      context = context.to_h.transform_keys(&:to_s)
      default = context.key?('default') ? definition.cast(context.delete('default')) : definition.default_value
      setting = @settings[name]

      if setting
        lookup = Conditions::Lookup.new(assigns(definition, context))
        setting.refinements.each do |refinement|
          next unless refinement.enabled? && !refinement.value.nil?
          next unless refinement.rules.met?(lookup)

          return Resolution.new(name: name, value: refinement.value, source: :refinement, refinement: refinement)
        end

        return Resolution.new(name: name, value: setting.value, source: :value, refinement: nil) unless setting.value.nil?
      end

      Resolution.new(name: name, value: default, source: :default, refinement: nil)
    end

    private

    # The context the refinements look at: as given, with the default of the
    # setting's context roots that aren't (config.context_default), and 1.x's
    # keys at the variables they are now (config.legacy_key)
    def assigns(definition, context)
      definition.context.each_key do |root|
        default = Vario.config.context_defaults[root]
        context[root] = default.respond_to?(:call) ? default.call : default if default && !context.key?(root)
      end

      Vario.config.legacy_keys.each do |key, variable|
        next unless context.key?(key)

        *path, last = variable.split('.')
        target = path.inject(context) do |hash, part|
          break unless hash.is_a?(Hash)

          hash[part] = (hash[part] || {}).then { |value| value.is_a?(Hash) ? value.transform_keys(&:to_s) : value }
        end
        target["#{last}_id"] = context[key] if target.is_a?(Hash) && !target.key?(last) && !target.key?("#{last}_id")
      end

      context
    end
  end

  # A setting's value in a context and where it comes from: :refinement
  # (refinement is the one), :value (the settable's own) or :default
  Resolution = Data.define(:name, :value, :source, :refinement)
end
