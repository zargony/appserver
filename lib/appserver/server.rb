require 'ostruct'

module Appserver
  class Server < OpenStruct
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

    def initialize (options = {})
      settings = DEFAULTS
      # Load configuration from given server directory, fall back to the current directory
      @dir = options.delete(:dir) || Dir.pwd
      config_file = File.join(@dir, 'appserver.yml')
      if File.exist?(config_file)
        settings.merge!(YAML.load_file(config_file).symbolize_keys!)
        @dir_initialized = true
      end
      # Let command line options override any settings
      settings.merge!(options)
      super(settings)
    end

    def dir_initialized?
      @dir_initialized
    end
  end
end
