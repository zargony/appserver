require 'etc'

module Appserver
  class App < Struct.new(:server_dir, :name, :branch, :ruby, :environment, :user, :group, :instances, :preload,
                         :env_whitelist, :env, :max_cpu_usage, :max_memory_usage, :usage_check_cycles, :http_check_timeout,
                         :domain, :hostname, :ssl_cert, :ssl_key, :public_dir)

    SETTINGS_DEFAULTS = {
      :branch => 'master',
      :ruby => Utils.find_in_path('ruby') || '/usr/bin/ruby',
      :environment => 'production',
      :user => nil,
      :group => nil,
      :instances => Utils.number_of_cpus || 1,
      :preload => false,
      :env_whitelist => [],
      :env => {},
      :max_cpu_usage => nil,
      :max_memory_usage => nil,
      :usage_check_cycles => 5,
      :http_check_timeout => 30,
      :domain => Utils.system_domainname,
      :hostname => nil,
      :ssl_cert => nil,
      :ssl_key => nil,
      :public_dir => 'public',
    }

    SETTINGS_EXPAND = [ :ssl_cert, :ssl_key ]

    ALWAYS_WHITELIST = ['PATH', 'PWD', 'GEM_HOME', 'GEM_PATH', 'RACK_ENV']

    def initialize (server_dir, name, config)
      self.server_dir, self.name = server_dir, name
      # Apply configuration settings
      config.apply!(self, name)
      # Use the directory owner as the user to run instances under by default
      self.user ||= exist? ? Etc.getpwuid(File.stat(path).uid).name : 'www-data'
      # Use a subdomain if no hostname was given specifically for this app
      self.hostname ||= "#{name.gsub(/[^a-z0-9_-]+/i, '_')}.#{domain}"
    end

    def path
      File.join(server_dir.apps_path, name)
    end

    def exist?
      File.directory?(path)
    end

    def revision_file
      File.join(path, 'REVISION')
    end

    def ssl?
      ssl_cert && ssl_key
    end

    def public_path
      File.expand_path(public_dir, path)
    end

    def rack_config
      File.join(path, 'config.ru')
    end

    def rack?
      File.exist?(rack_config)
    end

    def unicorn_config
      File.expand_path('../unicorn.conf.rb', __FILE__)
    end

    def gem_file
      File.join(path, 'Gemfile')
    end

    def bundle_path
      File.join(path, '.bundle')
    end

    def pid_file
      File.join(server_dir.tmp_path, "#{name}.pid")
    end

    def socket
      File.join(server_dir.tmp_path, "#{name}.socket")
    end

    def server_log
      File.join(server_dir.log_path, "#{name}.server.log")
    end

    def access_log
      File.join(server_dir.log_path, "#{name}.access.log")
    end

    def setup_env!
      # Apply whitelist if set
      if env_whitelist != '*' && env_whitelist != ['*']
        ENV.reject! { |key, value| !env_whitelist.include?(key) && !ALWAYS_WHITELIST.include?(key) }
      end
      # Set environment variables
      if env
        ENV.update(env)
      end
      # Setup gem bundle if present
      if File.exist?(gem_file) && File.directory?(bundle_path)
        ENV.update({ 'GEM_HOME' => bundle_path, 'BUNDLE_PATH' => bundle_path })
        # Remember load paths of required gems (which use autloading), before bundler takes away the load path
        remember_paths = $LOAD_PATH.select { |path| path =~ %r(/(unicorn|rack|appserver)[^/]*/) }
        # Load bundler and setup gem bundle
        require 'bundler'
        Bundler.setup
        # Re-add remembered load paths
        $LOAD_PATH.unshift *remember_paths
      end
    end

    def start_server_cmd
      if rack?
        "#{ruby} -S -- unicorn -E #{environment} -Dc #{unicorn_config} #{rack_config}"
      end
    end

    def start_server?
      !!start_server_cmd
    end

    def start_server
      exec start_server_cmd if start_server?
    end

    def server_pid
      File.readlines(pid_file)[0].to_i rescue nil
    end

    def stop_server
      Process.kill(:TERM, server_pid)
    end

    def restart_server
      Process.kill(:USR2, server_pid)
    end

    def reopen_server_log
      Process.kill(:USR1, server_pid)
    end
  end
end
