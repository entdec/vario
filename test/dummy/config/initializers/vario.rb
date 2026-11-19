# frozen_string_literal: true

Vario.setup do |config|
  config.current_settable = -> { Current.account }
  config.context_default :environment, -> { Rails.env }

  # 1.x's, for its Setting#value_for in the parity suite
  config.key :environment, name: 'Environment', type: :select, collection_proc: -> { [%w[Production production], %w[Test test], %w[Development development]] }, value_proc: -> { Rails.env }
end
