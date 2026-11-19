require_relative 'vario/engine'
require_relative 'vario/config'
require_relative 'vario/settable'
require_relative 'vario/settings_reader'
require_relative 'vario/card'
require_relative 'vario/types'
require_relative 'vario/topic'
require_relative 'vario/settable_topic'
require_relative 'vario/resolver'
require_relative 'vario/converter'
require_relative 'vario/migrator'
require_relative 'vario/topic_reader'
require_relative 'vario/context_variables'
require_relative 'vario/action_view_helpers'
require_relative 'vario/active_record_helpers'
require_relative 'vario/api'

module Vario
  class Error < StandardError; end
  class UnknownSetting < Error; end

  class << self
    attr_reader :config

    def setup
      @config = Vario::Config.new
      yield config
    end

    # Signs what a page of the host's gives the settings it renders
    # (render_vario_settings)
    def verifier
      Rails.application.message_verifier('vario/values')
    end
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include ActiveRecordHelpers
  end

  ActiveSupport.on_load(:action_view) do
    include ActionViewHelpers
  end
end
