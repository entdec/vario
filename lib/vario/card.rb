# frozen_string_literal: true

module Vario
  # What a card (vario/shared/_card) shows besides its title: the actions and
  # tabs the block given to vario_card adds
  class Card
    Tab = Data.define(:id, :title, :padding, :content)

    attr_reader :tabs, :actions

    def initialize(view)
      @view = view
      @tabs = []
      @actions = []
    end

    def tab(id, title: nil, padding: true, &block)
      @tabs << Tab.new(id: id.to_s.parameterize(separator: '_'), title: title || id.to_s.humanize, padding: padding, content: @view.capture(&block))
      nil
    end

    def action(&block)
      @actions << @view.capture(&block)
      nil
    end
  end
end
