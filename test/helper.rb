require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'mocha'

require 'appserver'

class Test::Unit::TestCase

  FIXTURES_PATH = File.expand_path('../fixtures', __FILE__)

  def fixture (name)
    File.join(FIXTURES_PATH, name)
  end

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

  # Creates a dummy rack app in the given path
  def create_dummy_rack_app (path)
    FileUtils.mkdir_p path
    FileUtils.cp fixture('hello_world.ru'), File.join(path, 'config.ru')
  end
end
