require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'appserver'
    gem.summary = 'Monit/Nginx/Unicorn application server configurator using deployment via git'
    gem.description = 'This little tool automatically generates server configs for Monit, Nginx and Unicorn to host your Rack-based (Rails) applications. Running it automatically in git post-receive hooks provides an automatic deployment of applications whenever the repository is updated on the server.'
    gem.email = 'zargony@gmail.com'
    gem.homepage = 'http://github.com/zargony/appserver'
    gem.authors = ['Andreas Neuhaus']
    gem.requirements << 'a server with Monit, Nginx and Git'
    gem.add_dependency 'unicorn', '~> 0.97'
    gem.add_dependency 'git', '~> 1.2'
    gem.has_rdoc = false
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end
