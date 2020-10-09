module Vario
  class Config
    attr_writer :logger, :current_settable
    attr_reader :keys, :settable_types, :settable_settings
    attr_accessor :base_controller, :admin_layout

    def initialize
      @logger               = Logger.new(STDOUT)
      @logger.level         = Logger::INFO
      @keys = {}
      @base_controller = '::ApplicationController'
      @settable_types = {}
      @settable_settings = {}
      @settable_type = nil
      @current_settable = nil
      @admin_layout = 'application'
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

    # If true, raise Vario::UnknownSetting if a unknown setting is retrieved, if false unknown settings return nil
    def raise_on_undefined(value, options = {})
      settable_type = options.delete(:settable_type) || @settable_type
      settable_types[settable_type] ||= {}
      settable_types[settable_type][:raise_on_undefined] = value
    end

    # If true, a new setting will be saved for settings that do not exist.
    def create_on_request(value, options = {})
      settable_type = options.delete(:settable_type) || @settable_type
      settable_types[settable_type] ||= {}
      settable_types[settable_type][:create_on_request] = value
      settable_types[settable_type][:default_keys] = options[:with_keys]
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

    def create_on_request?(settable_type)
      settable_types.dig(settable_type, :create_on_request)
    end

    def raise_on_undefined?(settable_type)
      settable_types.dig(settable_type, :raise_on_undefined)
    end

    def default_keys?(settable_type)
      settable_types.dig(settable_type, :default_keys) || []
    end

    def pre_create_settings(settable)
      return unless settable_settings[settable.class.name]
      settable_settings[settable.class.name].keys.each do |key|
        s = settable.settings.find_or_initialize_by(name: key)
        s.save unless s.persisted?
      end
    end
  end
end
