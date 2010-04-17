require 'tempfile'

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
  replace_file 'monitrc' do |f|
    f.puts '# TODO...'
    # TODO
  end
end

task :nginx do |t|
  puts 'Creating nginx configuration...'
  replace_file 'nginx.conf' do |f|
    f.puts '# TODO...'
    # TODO ...
  end
end
