require_dependency 'vario/engine'
require_dependency 'vario/config'
require_dependency 'vario/active_record_helpers'
require_dependency 'vario/i18n_backend'

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
