require 'vario/engine'
require 'vario/config'
require 'vario/active_record_helpers'

module Vario
  class Error < StandardError; end

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
