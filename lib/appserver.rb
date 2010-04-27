module Appserver
  ROOT = File.expand_path('..', __FILE__)
  autoload :Command,    "#{ROOT}/appserver/command"
  autoload :Server,     "#{ROOT}/appserver/server"
  autoload :App,        "#{ROOT}/appserver/app"
  autoload :Repository, "#{ROOT}/appserver/repository"
end
