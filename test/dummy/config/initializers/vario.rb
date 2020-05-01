# frozen_string_literal: true

Vario.setup do |config|
  config.key :environment, name: 'Environment', type: :select, collection_proc: -> { [%w[Production production], %w[Test test], %w[Development development]] }, value_proc: -> { Rails.env }

  config.for_settable_type 'Account' do |settable|
    settable.raise_on_undefined true

    settable.setting 'print_node.api_key', description: 'Print node API key', keys: %i[environment]
    settable.setting 'hide_couriers', type: :boolean, description: 'Hide couriers from dashboard', default: true
  end
end
