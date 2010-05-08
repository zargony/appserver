require 'etc'

module Appserver
  class App < Struct.new(:server_dir, :name, :branch, :ruby, :environment, :user, :group, :instances, :preload,
                         :env_whitelist, :env, :max_cpu_usage, :max_memory_usage, :usage_check_cycles, :http_check_timeout,
                         :hostname, :ssl_cert, :ssl_key, :public_dir)
    include Utils

    DEFAULTS = {
      :branch => 'master',
      :ruby => find_in_path('ruby') || '/usr/bin/ruby',
      :environment => 'production',
      :user => nil,
      :group => nil,
      :instances => number_of_cpus || 1,
      :preload => false,
      :env_whitelist => [],
      :env => {},
      :max_cpu_usage => nil,
      :max_memory_usage => nil,
      :usage_check_cycles => 5,
      :http_check_timeout => 30,
      :hostname => system_domainname,
      :ssl_cert => nil,
      :ssl_key => nil,
      :public_dir => 'public',
    }

    ALWAYS_WHITELIST = ['PATH', 'PWD', 'GEM_HOME', 'GEM_PATH', 'RACK_ENV']

    def initialize (server_dir, name, config)
      self.server_dir, self.name = server_dir, name
      # Application-specific configuration settings
      appconfig = (config[:apps] || {})[name.to_sym] || {}
      DEFAULTS.each do |key, default_value|
        self[key] = appconfig[key] || config[key] || default_value
      end
      # Use the directory owner as the user to run instances under by default
      self.user ||= exist? ? Etc.getpwuid(File.stat(path).uid).name : 'www-data'
      # Make array from comma separated list
      self.env_whitelist = env_whitelist.split(/\s*,\s*/) if String === env_whitelist
      # Use a subdomain of the default hostname if no hostname was given specifically for this app
      self.hostname = "#{name.gsub(/[^a-z0-9_-]+/i, '_')}.#{hostname}" unless appconfig[:hostname]
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
      if env_whitelist != ['*']
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

    def start_cmd
      if rack?
        "#{ruby} -S -- unicorn -E #{environment} -Dc #{unicorn_config} #{rack_config}"
      end
    end

    def stop_cmd
      "kill -TERM `cat #{pid_file}`"
    end

    def reopen_cmd
      "kill -USR1 `cat #{pid_file}`"
    end

    def restart_cmd
      "kill -USR2 `cat #{pid_file}`"
    end

    def log_reopen_cmds
      {
        server_log => reopen_cmd,
        access_log => server_dir.nginx_reopen,
      }
    end
  end
end
