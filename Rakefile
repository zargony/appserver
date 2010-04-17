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

class Server < OpenStruct
  DEFAULTS = {
    :monit_conf => 'monitrc',
    :monit_reload => '/usr/sbin/monit',
    :nginx_conf => 'nginx.conf',
    :nginx_reload => '/usr/sbin/nginx -s reload',
  }

  def self.load (filename = 'config.yml')
    config = YAML.load_file(filename) rescue nil
    new(config)
  end

  def initialize (config)
    config = DEFAULTS.merge((config || {}).symbolize_keys!)
    super(config)
  end

  def update_monit
    puts 'Creating monit configuration...'
    replace_file monit_conf do |f|
      f.puts %Q(# Automagically generated config)
      f.puts %Q(check file monit_conf with path #{File.expand_path(monit_conf)})
      f.puts %Q(  if changed checksum then exec "#{monit_reload}")
      f.puts %Q(check file nginx_conf with path #{File.expand_path(nginx_conf)})
      f.puts %Q(  if changed checksum then exec "#{nginx_reload}")
    end
  end

  def update_nginx
    puts 'Creating nginx configuration...'
    replace_file nginx_conf do |f|
      f.puts %Q(# Automagically generated config)
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
