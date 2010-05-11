require 'fileutils'

module Appserver
  class DirectoryAlreadyExistError < RuntimeError; end
  class NotInitializedError < RuntimeError; end

  class ServerDir < Struct.new(:path, :monit_conf, :monit_reload, :nginx_conf, :nginx_reload, :nginx_reopen, :logrotate_conf)

    CONFIG_FILE_NAME = 'appserver.conf.rb'

    SETTINGS_DEFAULTS = {
      :monit_conf => 'monitrc',
      :monit_reload => '/usr/sbin/monit reload',
      :nginx_conf => 'nginx.conf',
      :nginx_reload => '/usr/sbin/nginx -s reload',
      :nginx_reopen => '/usr/sbin/nginx -s reopen',
      :logrotate_conf => 'logrotate.conf',
    }

    SETTINGS_EXPAND = [ :monit_conf, :nginx_conf, :logrotate_conf ]

    def self.config_file_template
      File.expand_path("../#{CONFIG_FILE_NAME}", __FILE__)
    end

    def self.discover (path = '.', options = {})
      if File.exist?(File.join(path, CONFIG_FILE_NAME))
        new(path, options)
      elsif path != '/'
        discover(File.expand_path('..', path), options)
      else
        raise NotInitializedError
      end
    end

    def self.init (path, options = {})
      raise DirectoryAlreadyExistError if File.exist?(path) && !options[:force]
      FileUtils.mkdir_p path
      Dir.chdir(path) do
        FileUtils.cp config_file_template, CONFIG_FILE_NAME
        FileUtils.mkdir_p ['apps', 'tmp', 'log']
      end
      new(path, options)
    end

    def initialize (path, options = {})
      self.path = File.expand_path(path)
      # Load and apply configuration settings
      app_keys = App::SETTINGS_DEFAULTS.keys
      global_keys = SETTINGS_DEFAULTS.keys + App::SETTINGS_DEFAULTS.keys
      @config = Configurator.new(File.exist?(config_file) ? config_file : nil, global_keys, app_keys)
      @config.apply!(self)
    end

    def config_file
      File.join(path, CONFIG_FILE_NAME)
    end

    def appserver_cmd (*args)
      cmd = File.expand_path('../../../bin/appserver', __FILE__)
      "#{cmd} -d #{path} #{args.join(' ')}"
    end

    def apps_path
      File.join(path, 'apps')
    end

    def tmp_path
      File.join(path, 'tmp')
    end

    def log_path
      File.join(path, 'log')
    end

    def app (name)
      @apps ||= {}
      @apps[name] ||= App.new(self, name, @config)
    end

    def apps
      Dir.glob(File.join(apps_path, '*')).
        select { |f| File.directory?(f) }.
        map { |f| File.basename(f) }.
        reject { |f| f =~ /\.(tmp|old|new)$/ }.
        map { |name| app(name) }
    end

    def repository (path)
      @repositories ||= {}
      @repositories[File.expand_path(path, self.path)] ||= Repository.new(self, path, @config)
    end

    def write_configs
      Monit.write_config(self)
      Nginx.write_config(self)
      Logrotate.write_config(self)
    end
  end
end
