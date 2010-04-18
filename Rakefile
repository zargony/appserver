require 'ostruct'
require 'tempfile'
require 'yaml'

Dir.chdir(File.expand_path('..', __FILE__))

class Hash
  def symbolize_keys!
    keys.each { |key| self[key.to_sym] = delete(key) }
    self
  end
end

class App < OpenStruct
  attr_reader :server

  def initialize (server, name, settings)
    super(settings)
    [:thin, :thin_opts, :instances, :max_cpu_usage, :max_memory_usage, :usage_check_cycles, :http_check_timeout].each do |key|
    @server = server
    self.name = name
      send("#{key}=", server.send(key)) unless send(key)
    end
    self.hostname ||= "#{name}.#{server.domain}"
  end

  def dir
    File.expand_path(name)
  end

  def rack_config
    File.expand_path('config.ru', dir)
  end

  def rack?
    File.exist?(rack_config)
  end

  def write_monit_config (f)
    f.puts %Q()
    f.puts %Q(# Application: #{name})
    if rack?
      cyclecheck = usage_check_cycles > 1 ? " for #{usage_check_cycles} cycles" : ''
      (0...instances).each do |i|
        thin_cmd, thin_args = thin.split(/\s/, 2)
        pidfile = File.expand_path("#{name}_#{i}.pid")
        socket = File.expand_path("#{name}_#{i}.socket")
        f.puts %Q(check process #{name}_#{i} with pidfile #{pidfile})
        f.puts %Q(  start program = "/sbin/start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{thin_cmd} -- #{thin_args} -S #{socket} -R #{rack_config} -d -P #{pidfile} #{thin_opts} start")
        f.puts %Q(  stop program = "/sbin/start-stop-daemon --stop --quiet --pidfile #{pidfile} --exec #{thin_cmd}")
        f.puts %Q(  if totalcpu usage > #{max_cpu_usage}#{cyclecheck} then restart) if max_cpu_usage
        f.puts %Q(  if totalmemory usage > #{max_memory_usage}#{cyclecheck} then restart) if max_memory_usage
        f.puts %Q(  if failed unixsocket #{socket} protocol http request "/" hostheader "#{hostname.split(/\s/)[0]}" timeout #{http_check_timeout} then restart) if http_check_timeout > 0
        f.puts %Q(  if 5 restarts within 5 cycles then timeout)
        f.puts %Q(  group #{name})
      end
    end
  end

  def write_nginx_config (f)
    f.puts %Q()
    f.puts %Q(# Application: #{name})
    # TODO ...
  end
end

class Server < OpenStruct
  DEFAULTS = {
    :monit_conf => 'monitrc',
    :monit_reload => '/usr/sbin/monit',
    :nginx_conf => 'nginx.conf',
    :nginx_reload => '/usr/sbin/nginx -s reload',
    :thin => '/usr/local/bin/thin',
    :thin_opts => '-e production',
    :instances => 3,
    :max_cpu_usage => nil,
    :max_memory_usage => nil,
    :usage_check_cycles => 5,
    :http_check_timeout => 30,
    :domain => `/bin/hostname -f`.chomp.gsub(/^[^.]+\./, ''),
  }

  def self.load (filename = 'config.yml')
    config = YAML.load_file(filename) rescue nil
    new(config)
  end

  def initialize (config)
    config = DEFAULTS.merge((config || {}).symbolize_keys!)
    appconfigs = config.delete(:apps) || {}
    super(config)
    @apps = appconfigs.inject([]) do |memo, (name, settings)|
      memo << App.new(self, name, settings)
    end
  end

  attr_reader :apps

  def update_monit
    puts 'Creating monit configuration...'
    replace_file monit_conf do |f|
      f.puts %Q(# Automagically generated config)
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
    puts 'Creating nginx configuration...'
    replace_file nginx_conf do |f|
      f.puts %Q(# Automagically generated config)
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

task :default => [ :monit, :nginx ]
task :monit do |t| server.update_monit; end
task :nginx do |t| server.update_nginx; end
