require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'mocha'

require 'appserver'
require 'tmpdir'

class Test::Unit::TestCase

  SAMPLE_APPS_PATH = File.expand_path('../apps', __FILE__)

  # Runs the given block in an empty, temporary direcory
  def in_empty_dir (&block)
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        yield
      end
    end
  end

  # Runs the given block in an initialized appserver directory
  def in_server_dir (&block)
    in_empty_dir do
      yield Appserver::ServerDir.init('.', :force => true)
    end
  end

  # Copies the named sample app to the given path
  def create_app (name, path)
    raise 'Target path already exist' if File.exist?(path)
    FileUtils.cp_r File.join(SAMPLE_APPS_PATH, name), path
  end
  end
end
