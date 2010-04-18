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
  def initialize (server, name, settings)
    super(settings)
    self.server, self.name = server, name
    [:rack_server, :instances].each do |key|
      send("#{key}=", server.send(key)) unless send(key)
    end
    self.hostname ||= "#{name}.#{server.domain}"
  end

  def dir
    File.expand_path(name)
  end

  def base_port
    server.base_port + 100 * server.apps.index(self)
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
      (0...instances).each do |i|
        pidfile = File.expand_path("#{name}_#{i}.pid")
        cmd, args = rack_server.gsub(/PORT/, "#{base_port+i}").gsub(/CONFIG/, rack_config).split(/\s/, 2)
        f.puts %Q(check process app_#{name}_#{i} with pidfile #{pidfile})
        f.puts %Q(  start program = "/sbin/start-stop-daemon --start --quiet --pidfile #{pidfile} --exec #{cmd} -- #{args}")
        f.puts %Q(  stop program = "/sbin/start-stop-daemon --stop --quiet --pidfile #{pidfile} --exec #{cmd}")
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
    :rack_server => 'thin -a 127.0.0.1 -p PORT -e production -R CONFIG start',
    :instances => 3,
    :base_port => 20000,
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
