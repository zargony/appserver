module Appserver
  ROOT = File.expand_path('..', __FILE__)
  autoload :Command, "#{ROOT}/appserver/command"
  autoload :Server,  "#{ROOT}/appserver/server"
end

require "#{Appserver::ROOT}/appserver/core_ext"
