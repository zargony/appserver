module Appserver
  class App < Struct.new(:thin, :thin_opts, :instances, :pids_dir, :sockets_dir, :server_log, :max_cpu_usage,
                         :max_memory_usage, :usage_check_cycles, :http_check_timeout, :hostname, :access_log,
                         :public_dir)
    DEFAULTS = {
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
      :hostname => `/bin/hostname -f`.chomp.gsub(/^[^.]+\./, ''),
      :access_log => 'log/access.log',
      :public_dir => 'public',
    }

    attr_reader :server, :name

    def initialize (server, name, settings = {})
      super()
      @server, @name = server, name
      appsettings = ((settings[:apps] || {})[name] || {}).symbolize_keys!
      members.each do |key|
        self[key] = appsettings[key] || settings[key] || DEFAULTS[key]
      end
      # Use a subdomain of the default hostname if no hostname was given specifically for this app
      self.hostname = "#{name}.#{hostname}" unless appsettings[:hostname]
    end

    def dir
      File.join(server.dir, name)
    end

    def rack_config
      File.join(dir, 'config.ru')
    end

    def rack?
      File.exist?(rack_config)
    end

    def pidfile (instance)
      File.join(pids_dir, "#{name}_#{instance.to_i}.pid")
    end

    def socket (instance)
      File.join(sockets_dir, "#{name}_#{instance.to_i}.socket")
    end

    def write_monit_config (f)
      f.puts %Q()
      f.puts %Q(# Application: #{name})
      if rack?
        cyclecheck = usage_check_cycles > 1 ? " for #{usage_check_cycles} cycles" : ''
        (0...instances).each do |i|
          f.puts %Q(check process #{name}_#{i} with pidfile #{File.expand_path(pidfile(i), dir)})
          f.puts %Q(  start program = "TODO")
          f.puts %Q(  stop program = "TODO")
          f.puts %Q(  if totalcpu usage > #{max_cpu_usage}#{cyclecheck} then restart) if max_cpu_usage
          f.puts %Q(  if totalmemory usage > #{max_memory_usage}#{cyclecheck} then restart) if max_memory_usage
          f.puts %Q(  if failed unixsocket #{File.expand_path(socket(i), dir)} protocol http request "/" timeout #{http_check_timeout} seconds then restart) if http_check_timeout > 0
          f.puts %Q(  if 5 restarts within 5 cycles then timeout)
          f.puts %Q(  group #{name})
        end
      end
    end

    def write_nginx_config (f)
      f.puts ""
      f.puts "# Application: #{name}"
      if rack?
        f.puts "upstream #{name}_cluster {"
        (0...instances).each do |i|
          f.puts "  server unix:#{File.expand_path(socket(i))} fail_timeout=0;"
        end
        f.puts "}"
        f.puts "server {"
        f.puts "  listen 80;"
        f.puts "  server_name #{hostname};"
        f.puts "  root #{File.expand_path(public_dir, dir)};"
        f.puts "  access_log #{File.expand_path(access_log)};"
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
  end
end
