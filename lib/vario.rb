require_relative 'vario/engine'
require_relative 'vario/config'
require_relative 'vario/settable'
require_relative 'vario/settings'
require_relative 'vario/active_record_helpers'

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
end
