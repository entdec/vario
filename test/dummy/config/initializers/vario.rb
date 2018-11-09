# frozen_string_literal: true

Vario.setup do |config|
  config.current_settable = -> { Channel.current }
  config.key :level_one, name: 'Level one', type: :select, collection_proc: -> { [%w[Option1 one] %w[Option2 two]] }
  config.key :level_two, name: 'Level two', type: :select, collection_proc: -> { [%w[Option1 one] %w[Option2 two]] }
  config.key :environment, name: 'Environment', type: :select, collection_proc: -> { [%w[Production production], %w[Development development]] }, value_proc: -> { Rails.env }

  config.translation_settable = -> { Praesens.current_scribo_site }

  config.for_settable_type 'Scribo::Site' do |settable|
    settable.raise_on_undefined false
    settable.create_on_request true, with_keys: %i[retailer_id]
  end

  config.for_settable_type 'Channel' do |settable|
    settable.raise_on_undefined true

    settable.setting 'print_node.api_key', description: 'Print node API key'
    settable.setting 'hide_couriers', description: 'Hide couriers from dashboard', default: true
  end
end
