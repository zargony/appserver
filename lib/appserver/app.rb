require 'etc'

module Appserver
  class App < Struct.new(:server, :name, :branch, :ruby, :environment, :user, :group, :instances, :preload,
                         :max_cpu_usage, :max_memory_usage, :usage_check_cycles, :http_check_timeout,
                         :hostname, :public_dir)
    include Utils

    DEFAULTS = {
      :branch => 'master',
      :ruby => find_in_path('ruby') || '/usr/bin/ruby',
      :environment => 'production',
      :user => nil,
      :group => nil,
      :instances => 3,
      :preload => false,
      :max_cpu_usage => nil,
      :max_memory_usage => nil,
      :usage_check_cycles => 5,
      :http_check_timeout => 30,
      :hostname => system_domainname,
      :public_dir => 'public',
    }

    def self.unicorn_config
      File.expand_path('../unicorn.conf.rb', __FILE__)
    end

    def initialize (server, name, config)
      super()
      self.server, self.name = server, name
      appconfig = (config[:apps] || {})[name.to_sym] || {}
      DEFAULTS.each do |key, default_value|
        self[key] = appconfig[key] || config[key] || default_value
      end
      # Use the directory owner as the user to run instances under by default
      self.user ||= exist? ? Etc.getpwuid(File.stat(dir).uid).name : 'www-data'
      # Use a subdomain of the default hostname if no hostname was given specifically for this app
      self.hostname = "#{name.gsub(/[^a-z0-9_-]+/i, '_')}.#{hostname}" unless appconfig[:hostname]
    end

    def dir
      File.join(server.apps_dir, name)
    end

    def exist?
      File.exist?(dir)
    end

    def rack_config
      File.join(dir, 'config.ru')
    end

    def rack?
      File.exist?(rack_config)
    end

    def startable?
      rack?
    end

    def pid_file
      File.join(server.tmp_dir, "#{name}.pid")
    end

    def socket
      File.join(server.tmp_dir, "#{name}.socket")
    end

    def server_log
      File.join(server.log_dir, "#{name}.server.log")
    end

    def access_log
      File.join(server.log_dir, "#{name}.access.log")
    end

    def write_monit_config (f)
      f.puts %Q()
      f.puts %Q(# Application: #{name})
      if rack?
        cyclecheck = usage_check_cycles > 1 ? " for #{usage_check_cycles} cycles" : ''
        f.puts %Q(check process #{name} with pidfile #{expand_path(pid_file)})
        f.puts %Q(  start program = "#{ruby} -S -- unicorn -E #{environment} -Dc #{self.class.unicorn_config} #{rack_config}")
        f.puts %Q(  stop program = "/bin/bash -c 'kill -TERM `cat #{expand_path(pid_file)}`'")
        f.puts %Q(  if totalcpu usage > #{max_cpu_usage}#{cyclecheck} then restart) if max_cpu_usage
        f.puts %Q(  if totalmemory usage > #{max_memory_usage}#{cyclecheck} then restart) if max_memory_usage
        f.puts %Q(  if failed unixsocket #{expand_path(socket)} protocol http request "/" timeout #{http_check_timeout} seconds then restart) if http_check_timeout > 0
        f.puts %Q(  if 5 restarts within 5 cycles then timeout)
        f.puts %Q(  group appserver)
      end
    end

    def write_nginx_config (f)
      f.puts ""
      f.puts "# Application: #{name}"
      if rack?
        f.puts "upstream #{name}_cluster {"
        f.puts "  server unix:#{expand_path(socket)} fail_timeout=0;"
        f.puts "}"
        f.puts "server {"
        f.puts "  listen 80;"
        f.puts "  server_name #{hostname};"
        f.puts "  root #{expand_path(public_dir)};"
        f.puts "  access_log #{expand_path(access_log)};"
        f.puts "  location / {"
        f.puts "    proxy_set_header X-Real-IP $remote_addr;"
        f.puts "    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
        f.puts "    proxy_set_header Host $http_host;"
        f.puts "    proxy_redirect off;"
        # TODO: maintenance mode rewriting
        f.puts "    try_files $uri/index.html $uri.html $uri @#{name}_cluster;"
        f.puts "    error_page 500 502 503 504 /500.html;"
        f.puts "  }"
        f.puts "  location @#{name}_cluster {"
        f.puts "    proxy_pass http://#{name}_cluster;"
        f.puts "  }"
        f.puts "}"
      end
    end

    def write_logrotate_config (f)
      f.puts ""
      f.puts "# Application: #{name}"
      if rack?
        f.puts "#{expand_path(server_log)} {"
        f.puts "  missingok"
        f.puts "  delaycompress"
        f.puts "  sharedscripts"
        f.puts "  postrotate"
        f.puts "    kill -USR1 `cat #{expand_path(pid_file)}`"
        f.puts "  endscript"
        f.puts "}"
      end
    end

  protected

    def expand_path (path)
      File.expand_path(path, dir)
    end
  end
end
