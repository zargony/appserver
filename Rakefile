require 'ostruct'
require 'tempfile'
require 'yaml'

Dir.chdir(File.expand_path('..', __FILE__))

config = OpenStruct.new({
  'monit_conf' => 'monitrc',
  'monit_reload' => '/usr/sbin/monit',
  'nginx_conf' => 'nginx.conf',
  'nginx_reload' => '/usr/sbin/nginx -s reload',
}.merge(YAML.load_file('config.yml')))

def replace_file (filename)
  tempfile = Tempfile.new(['_', File.basename(filename)], File.dirname(filename))
  yield tempfile
  tempfile.close
  File.unlink(filename) if File.exist?(filename)
  File.rename(tempfile, filename)
end

task :default => [ :monit, :nginx ]

task :monit do |t|
  puts 'Creating monit configuration...'
  replace_file config.monit_conf do |f|
    f.puts %Q(# Automagically generated config)
    f.puts %Q(check file webapp_monitrc with path #{File.expand_path(config.monit_conf)})
    f.puts %Q(  if changed checksum then exec "#{config.monit_reload}")
    f.puts %Q(check file webapp_nginxconf with path #{File.expand_path(config.nginx_conf)})
    f.puts %Q(  if changed checksum then exec "#{config.nginx_reload}")
  end
end

task :nginx do |t|
  puts 'Creating nginx configuration...'
  replace_file config.nginx_conf do |f|
    f.puts %Q(# Automagically generated config)
  end
end
