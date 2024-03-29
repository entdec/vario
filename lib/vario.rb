require_relative 'vario/engine'
require_relative 'vario/config'
require_relative 'vario/settable'
require_relative 'vario/settings_reader'
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
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include ActiveRecordHelpers
  end

  ActiveSupport.on_load(:action_view) do
    include ActionViewHelpers
  end
end
