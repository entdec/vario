# frozen_string_literal: true

module Vario
  # What a setting's refinements can look at, for the conditions editor: the
  # variables of its context (Topic::Definition#context) a level at a time,
  # as Liquidum's, and the records an object variable can be.
  #
  #   variables = ContextVariables.new(definition.context)
  #   variables.at('')                      # location, order, order_type
  #   variables.at('order')                 # the order drop's variables
  #   variables.describe('order.customer')  # => ["Order › Customer", "object"]
  #   variables.model('order.customer')     # => Customer
  #
  # A root that is a model (location: Location) is an object without
  # variables of its own; a drop's are Liquidum's.
  class ContextVariables
    def initialize(context)
      @context = context.to_h { |name, root| [name.to_s, root] }
      @models = @context.select { |_name, root| model?(root) }
      @liquidum = Liquidum::Variables.new(@context.reject { |name, _root| @models.key?(name) })
    end

    def at(path)
      names = path.to_s.split('.')
      return @context.keys.filter_map { |name| root(name) } if names.empty?
      return [] if @models.key?(names.first)

      @liquidum.at(path)
    end

    # Its label, the labels on its way ("Order › Customer"), and type
    def describe(path)
      *parents, name = path.to_s.split('.')
      labels = []
      variable = nil
      [*parents, name].each_with_index do |part, index|
        variable = at(parents.first(index).join('.'))&.find { |candidate| candidate.name == part }
        return [path, nil] unless variable

        labels << variable.label
      end
      [labels.join(' › '), variable.type]
    end

    # The model of an object variable, whose records it can be
    def model(path)
      names = path.to_s.split('.')
      return @models[names.first] if names.size == 1 && @models.key?(names.first)

      *parents, name = names
      variable = at(parents.join('.'))&.find { |candidate| candidate.name == name }
      drop = variable&.drop || (@context[name] if parents.empty?)
      drop.model if drop.respond_to?(:model)
    end

    private

    def model?(root)
      root.is_a?(Class) && root < ActiveRecord::Base
    end

    def root(name)
      return @liquidum.at('').find { |variable| variable.name == name } unless @models.key?(name)

      model = @models[name]
      Liquidum::Variable.new(name: name, label: model.model_name.human, type: 'object', hint: nil, drop: nil, collection: false)
    end
  end
end
