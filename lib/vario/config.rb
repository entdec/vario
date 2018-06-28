module Vario
  class Configuration
    attr_writer :logger

    def initialize
      @logger               = Logger.new(STDOUT)
      @logger.level         = Logger::INFO
    end

    # Config: logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end
end
