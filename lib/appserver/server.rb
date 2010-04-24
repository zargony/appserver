require 'ostruct'
require 'yaml'

module Appserver
  class Server < OpenStruct
    class AlreadyInitializedError < RuntimeError
    end

    DEFAULTS = {
      :repo_dir => (Etc.getpwnam('git') rescue {})[:dir],
      :monit_conf => 'monitrc',
      :monit_reload => '/usr/sbin/monit reload',
      :nginx_conf => 'nginx.conf',
      :nginx_reload => '/usr/sbin/nginx -s reload',
      :thin => '/usr/local/bin/thin',
      :thin_opts => '-e production',
      :instances => 3,
      :pids_dir => 'tmp/pids',
      :sockets_dir => 'tmp/sockets',
      :server_log => 'log/server.log',
      :max_cpu_usage => nil,
      :max_memory_usage => nil,
      :usage_check_cycles => 5,
      :http_check_timeout => 30,
      :domain => `/bin/hostname -f`.chomp.gsub(/^[^.]+\./, ''),
      :access_log => 'log/access.log',
      :public_dir => 'public',
    }

    attr_reader :dir

    def config_file
      File.join(dir, 'appserver.yml')
    end

    def config_file_template
      File.expand_path('../appserver.yml', __FILE__)
    end

    def initialize (options = {})
      settings = DEFAULTS
      # Load configuration from given server directory, fall back to the current directory
      @dir = options.delete(:dir) || Dir.pwd
      if File.exist?(config_file)
        config_settings = YAML.load_file(config_file)
        settings.merge!((config_settings || {}).symbolize_keys!)
        @dir_initialized = true
      end
      # Let command line options override any settings
      settings.merge!(options)
      super(settings)
    end

    def dir_initialized?
      @dir_initialized
    end

    def initialize_dir
      raise AlreadyInitializedError if File.exist?(config_file)
      File.safe_replace(config_file) do |f|
        f.puts IO.read(config_file_template)
      end
    end
  end
end
