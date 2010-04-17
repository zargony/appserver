require 'ostruct'
require 'tempfile'
require 'yaml'

Dir.chdir(File.expand_path('..', __FILE__))

config = OpenStruct.new({
  'monitrc' => 'monitrc',
  'nginxconf' => 'nginx.conf',
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
  replace_file config.monitrc do |f|
    f.puts %Q(# Automagically generated config)
  end
end

task :nginx do |t|
  puts 'Creating nginx configuration...'
  replace_file config.nginxconf do |f|
    f.puts %Q(# Automagically generated config)
  end
end
