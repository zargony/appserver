module Appserver
  ROOT = File.expand_path('..', __FILE__)
  autoload :Utils,      "#{ROOT}/appserver/utils"
  autoload :Command,    "#{ROOT}/appserver/command"
  autoload :ServerDir,  "#{ROOT}/appserver/server_dir"
  autoload :App,        "#{ROOT}/appserver/app"
  autoload :Repository, "#{ROOT}/appserver/repository"
end
