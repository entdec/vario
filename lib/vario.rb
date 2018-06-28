require 'vario/engine'
require 'vario/config'
require 'vario/active_record_helpers'

module Vario
  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Config.new
      yield config
    end

    def setting(name, context = {})
      context.symbolize_keys!
      default = context.delete(:default)

      s = Vario::Setting.find_by(name: name)
      return default unless s
      s.value_for(context) || default
    end
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include ActiveRecordHelpers
  end
end
