module Appserver
  ROOT = File.expand_path('..', __FILE__)
  autoload :Utils,      "#{ROOT}/appserver/utils"
  autoload :Command,    "#{ROOT}/appserver/command"
  autoload :Server,     "#{ROOT}/appserver/server"
  autoload :App,        "#{ROOT}/appserver/app"
  autoload :Repository, "#{ROOT}/appserver/repository"
end
