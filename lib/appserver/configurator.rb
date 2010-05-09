module Appserver
  class Configurator < Struct.new(:settings)

    def initialize (config_file)
      self.settings = {}
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
      self.settings[@context] ||= {}
      self.settings[@context][method] = args[0]
      # TODO: raise error on unknown setting
    end
  end
end
