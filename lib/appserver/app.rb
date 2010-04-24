require 'ostruct'

module Appserver
  class App < OpenStruct
    attr_reader :server

    def initialize (server, name, settings = {})
      @server = server
      settings[:name] = name
      # Pull in settings from the server if it wasn't set specifically for the application
      [:thin, :thin_opts, :instances, :pids_dir, :sockets_dir, :server_log, :max_cpu_usage, :max_memory_usage, :usage_check_cycles, :http_check_timeout, :access_log, :public_dir].each do |key|
        settings[key] ||= server.send(key)
      end
      super(settings)
      # Use a subdomain of the main domain if no hostname was given
      self.hostname ||= "#{name}.#{server.domain}"
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
          f.puts %Q(  start program = "#{File.expand_path($0)} -d #{File.expand_path(server.dir)} start_instance #{name} #{i}")
          f.puts %Q(  stop program = "#{File.expand_path($0)} -d #{File.expand_path(server.dir)} stop_instance #{name} #{i}")
          f.puts %Q(  if totalcpu usage > #{max_cpu_usage}#{cyclecheck} then restart) if max_cpu_usage
          f.puts %Q(  if totalmemory usage > #{max_memory_usage}#{cyclecheck} then restart) if max_memory_usage
          f.puts %Q(  if failed unixsocket #{File.expand_path(socket(i), dir)} protocol http request "/" timeout #{http_check_timeout} seconds then restart) if http_check_timeout > 0
          f.puts %Q(  if 5 restarts within 5 cycles then timeout)
          f.puts %Q(  group #{name})
        end
      end
    end

    def instance_env
      { 'APP_NAME' => name, 'GEM_HOME' => Gem.dir, 'GEM_PATH' => Gem.path.join(':') }
    end

    def change_privileges
      target_uid, target_gid = File.stat(dir).uid, File.stat(dir).gid
      if Process.euid != target_uid || Process.egid != target_gid
        Process::GID.change_privilege(target_gid)
        Process::UID.change_privilege(target_uid)
      end
    end

    def start_instance (instance)
      change_privileges
      if rack?
        exec(instance_env, "#{thin} -S #{socket(instance)} -R #{rack_config} -d -l #{server_log} -P #{pidfile(instance)} #{thin_opts} start", :unsetenv_others => true)
      else
        raise "Don't know how to start this type of instance"
      end
    end

    def stop_instance (instance)
      change_privileges
      if rack?
        exec(instance_env, "#{thin} -l #{server_log} -P #{pidfile(instance)} stop", :unsetenv_others => true)
      end
    end

    def write_nginx_config (f)
      f.puts ""
      f.puts "# Application: #{name}"
      if rack?
        f.puts "upstream #{name}_cluster {"
        (0...instances).each do |i|
          f.puts "  server unix:#{File.expand_path(socket(i))};"
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
