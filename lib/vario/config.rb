module Vario
  class Config
    attr_writer :logger, :current_settable
    attr_reader :keys, :settable_settings

    def initialize
      @logger               = Logger.new(STDOUT)
      @logger.level         = Logger::INFO
      @keys = {}
      @settable_settings = {}
      @settable_type = nil
      @current_settable = nil
    end

    # Config setters

    def key(name, options)
      options.symbolize_keys!
      raise ArgumentError, 'name is required' unless options.keys.include?(:name)
      raise ArgumentError, 'type is required' unless options.keys.include?(:type)
      keys[name.to_s] = options
    end

    def setting(name, options = {})
      settable_type = options.delete(:settable_type) || @settable_type
      options[:type] ||= :string
      options[:keys] ||= []
      options[:default] ||= nil
      options[:description] ||= "Configuration for #{name}, possible on: #{(options[:keys] + ['default']).map(&:to_s).join(', ')}"
      settable_settings[settable_type] ||= {}
      settable_settings[settable_type][name.to_s] = options
    end

    def for_settable_type(settable_type)
      @settable_type = settable_type
      yield self
      @settable_type = nil
    end

    # Config retrieval

    # Config: logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    def current_settable
      @current_settable.is_a?(Proc) ? instance_exec(&@current_settable) : @current_settable
    end

    def settable_setting(settable_type, name)
      settable_settings.dig(settable_type, name)
    end

    def key_data_for(key)
      keys[key.to_s] || { name: key, type: :string, description: 'Not configured in initializer' }
    end
  end
end
