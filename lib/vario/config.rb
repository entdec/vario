module Vario
  class Config
    attr_reader :logger, :keys

    def initialize
      @logger               = Logger.new(STDOUT)
      @logger.level         = Logger::INFO
      @keys = {}
    end

    def key(name, options)
      options.symbolize_keys!
      raise ArgumentError, 'name is required' unless options.keys.include?(:name)
      raise ArgumentError, 'type is required' unless options.keys.include?(:type)
      keys[name.to_s] = options
    end

    # Config: logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end
end
