require 'rubygems'
require 'sinatra'
require 'erb'

set :app_file, __FILE__

get '/' do
  erb :index
end
