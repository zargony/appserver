module Appserver
  ROOT = File.expand_path('..', __FILE__)
  autoload :Command, "#{ROOT}/appserver/command"
end

require "#{Appserver::ROOT}/appserver/core_ext"
