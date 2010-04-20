require 'ostruct'
require 'etc'
require 'tempfile'
require 'yaml'

Dir.chdir(File.expand_path('..', __FILE__))

class Hash
  def symbolize_keys!
    keys.each { |key| self[key.to_sym] = delete(key) }
    self
  end
end

def rake_self
  "#{$0} -f #{File.expand_path(__FILE__)}"
end

class App < OpenStruct
  attr_reader :server

  def initialize (server, name, settings)
    super(settings)
    @server = server
    self.name = name
    [:thin, :thin_opts, :instances, :pids_dir, :sockets_dir, :server_log, :max_cpu_usage, :max_memory_usage, :usage_check_cycles, :http_check_timeout, :access_log, :public_dir].each do |key|
      send("#{key}=", server.send(key)) unless send(key)
    end
    [:pids_dir, :sockets_dir, :server_log, :access_log, :public_dir].each do |key|
      send("#{key}=", File.expand_path(send(key), dir))
    end
    self.hostname ||= "#{name}.#{server.domain}"
  end

  def dir
    File.expand_path(name)
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
        f.puts %Q(check process #{name}_#{i} with pidfile #{pidfile(i)})
        f.puts %Q(  start program = "#{rake_self} start APP_NAME=#{name} APP_INSTANCE=#{i}")
        f.puts %Q(  stop program = "#{rake_self} stop APP_NAME=#{name} APP_INSTANCE=#{i}")
        f.puts %Q(  if totalcpu usage > #{max_cpu_usage}#{cyclecheck} then restart) if max_cpu_usage
        f.puts %Q(  if totalmemory usage > #{max_memory_usage}#{cyclecheck} then restart) if max_memory_usage
        f.puts %Q(  if failed unixsocket #{socket(i)} protocol http request "/" timeout #{http_check_timeout} seconds then restart) if http_check_timeout > 0
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
        f.puts "  server unix:#{socket(i)};"
      end
      f.puts "}"
      f.puts "server {"
      f.puts "  listen 80;"
      f.puts "  server_name #{hostname};"
      f.puts "  root #{public_dir};"
      f.puts "  access_log #{access_log};"
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

class Server < OpenStruct
  DEFAULTS = {
    :git_dir => (Etc.getpwnam('git') rescue {})[:dir],
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

  def self.load (filename = 'config.yml')
    config = YAML.load_file(filename) rescue nil
    new(config)
  end

  def initialize (config)
    config = DEFAULTS.merge((config || {}).symbolize_keys!)
    @app_settings = config.delete(:apps) || {}
    super(config)
  end

  def apps
    @apps ||= @app_settings.inject([]) do |memo, (name, settings)|
      memo << App.new(self, name, settings)
    end
  end

  def app (name)
    apps.find { |app| app.name == name }
  end

  def install_git_hooks
    raise 'Path to git repositories not set and no user "git" present' unless git_dir
    raise "Path to git repositories (#{git_dir}) does not exist" unless Dir.exist?(git_dir)
    Dir.glob(File.expand_path('*.git', git_dir)).each do |repo|
      name = File.basename(repo, '.git')
      cmd = "#{rake_self} deploy APP_NAME=#{name}"
      hook = File.join(repo, 'hooks', 'post-receive')
      if !File.exist?(hook) || !File.executable?(hook)
        puts "Installing git post-receive hook to #{name}.git..."
        replace_file(hook) do |f|
          f.puts '#!/bin/sh'
          f.puts cmd
          f.chown File.stat(repo).uid, File.stat(repo).gid
          f.chmod 0755
        end
      elsif !File.readlines(hook).any? { |line| line =~ /^#{Regexp.escape(rake_self)}/ }
        puts "Couldn't install post-receive hook. Foreign hook script already present in #{name}.git!"
      else
        #puts "Hook already installed in #{name}.git"
      end
    end
  end

  def update_monit
    puts 'Updating monit configuration...'
    replace_file monit_conf do |f|
      f.puts %Q(# Automagically generated Monit config)
      # Let Monit reload itself if this configuration changes
      f.puts %Q(check file monit_conf with path #{File.expand_path(monit_conf)})
      f.puts %Q(  if changed checksum then exec "#{monit_reload}")
      # Reload Nginx if its configuration changes
      f.puts %Q(check file nginx_conf with path #{File.expand_path(nginx_conf)})
      f.puts %Q(  if changed checksum then exec "#{nginx_reload}")
      # Add application-specific Monit configuration
      apps.each { |app| app.write_monit_config(f) }
    end
  end

  def update_nginx
    puts 'Updating nginx configuration...'
    replace_file nginx_conf do |f|
      f.puts "# Automagically generated Nginx config"
      # The default server always responds with 403 Forbidden
      f.puts "server {"
      f.puts "  listen 80 default;"
      f.puts "  server_name _;"
      f.puts "  deny all;"
      f.puts "}"
      # Add application-specific Nginx configuration
      apps.each { |app| app.write_nginx_config(f) }
    end
  end

protected

  def replace_file (filename)
    tempfile = Tempfile.new(['_', File.basename(filename)], File.dirname(filename))
    yield tempfile
    tempfile.close
    File.unlink(filename) if File.exist?(filename)
    File.rename(tempfile, filename)
  end
end

server = Server.load

task :default => :update

desc 'Install post-receive hook into git repositories, that automatically deploy every time you push to a repository'
task :install => [ :git ]
task :git do |t| server.install_git_hooks; end

desc 'Update server configs for monit and nginx'
task :update => [ :monit, :nginx ]
task :monit do |t| server.update_monit; end
task :nginx do |t| server.update_nginx; end

task :start do |t| server.app(ENV['APP_NAME']).start_instance(ENV['APP_INSTANCE']); end
task :stop do |t| server.app(ENV['APP_NAME']).stop_instance(ENV['APP_INSTANCE']); end
