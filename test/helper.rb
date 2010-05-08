require 'rubygems'
require 'test/unit'
require 'mocha'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
$LOAD_PATH.unshift(File.expand_path('..', __FILE__))
require 'appserver'

class Test::Unit::TestCase

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
      yield Appserver::ServerDir.init('.')
    end
  end

  # Creates a dummy rack app in the given path
  def create_dummy_rack_app (path)
    FileUtils.mkdir_p path
    FileUtils.cp File.expand_path('../hello_world.ru', __FILE__), File.join(path, 'config.ru')
  end
end
