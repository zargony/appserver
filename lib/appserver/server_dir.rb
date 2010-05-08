require 'fileutils'
require 'yaml'

module Appserver
  class AlreadyInitializedError < RuntimeError; end
  class DirectoryNotEmptyError < RuntimeError; end
  class NotInitializedError < RuntimeError; end

  class ServerDir < Struct.new(:path, :monit_conf, :monit_reload, :nginx_conf, :nginx_reload, :nginx_reopen, :logrotate_conf)
    include Utils

    CONFIG_FILE_NAME = 'appserver.yml'

    DEFAULTS = {
      :monit_conf => 'monitrc',
      :monit_reload => '/usr/sbin/monit reload',
      :nginx_conf => 'nginx.conf',
      :nginx_reload => '/usr/sbin/nginx -s reload',
      :nginx_reopen => '/usr/sbin/nginx -s reopen',
      :logrotate_conf => 'logrotate.conf',
    }

    def self.config_file_template
      File.expand_path("../#{CONFIG_FILE_NAME}", __FILE__)
    end

    def self.discover (path = '.', options = {})
      if File.exist?(File.join(path, CONFIG_FILE_NAME))
        new(path, options)
      elsif path != '/'
        discover(File.expand_path('..', path), options)
      else
        nil
      end
    end

    def self.init (path, options = {})
      raise AlreadyInitializedError if discover(path) && !options[:force]
      FileUtils.mkdir_p path
      Dir.chdir(path) do
        raise DirectoryNotEmptyError if Dir.glob('*') != [] && !options[:force]
        FileUtils.cp config_file_template, CONFIG_FILE_NAME
        FileUtils.mkdir_p ['apps', 'tmp', 'log']
      end
      new(path, options)
    end

    def initialize (path, options = {})
      self.path = File.expand_path(path)
      # Load configuration settings
      @config = File.exist?(config_file) ? symbolize_keys(YAML.load_file(config_file) || {}) : {}
      DEFAULTS.each do |key, default_value|
        self[key] = @config[key] || default_value
      end
    end

    def config_file
      File.join(path, CONFIG_FILE_NAME)
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
        map { |name| app(name) }.
        select { |app| app.startable? }
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
