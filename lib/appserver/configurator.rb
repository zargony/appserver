module Appserver
  class Configurator < Struct.new(:settings, :global_keys, :context_keys)

    def initialize (config_file, global_keys = nil, context_keys = nil)
      self.settings = {}
      self.global_keys = global_keys
      self.context_keys = context_keys
      instance_eval(File.read(config_file), config_file) if config_file
    end

    def apply! (target, context = nil)
      settings = (self.settings[nil] || {}).dup
      settings.update(self.settings[context] || {}) if context
      target.class.const_get(:SETTINGS_DEFAULTS).each do |key, default_value|
        value = settings[key] || default_value
        value = File.expand_path(value, target.path) if value && target.class.const_get(:SETTINGS_EXPAND).include?(key)
        target.send("#{key}=", value)
      end
    end

    def context (context)
      saved_context = @context
      @context = context.to_s
      yield
      @context = saved_context
    end
    alias_method :app, :context

  protected

    def method_missing (method, *args)
      return super if !@context && global_keys && !global_keys.include?(method)
      return super if @context && context_keys && !context_keys.include?(method)
      self.settings[@context] ||= {}
      self.settings[@context][method] = args[0] if args.size > 0
    end
  end
end
