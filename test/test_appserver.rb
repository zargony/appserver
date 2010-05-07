require 'helper'

class TestAppserver < Test::Unit::TestCase

  def appserver (*args)
    cmd = File.expand_path('../../bin/appserver', __FILE__)
    bind = TOPLEVEL_BINDING.dup
    bind.eval("Object.send(:remove_const, :ARGV); ARGV = #{args.inspect}", __FILE__, __LINE__)
    bind.eval(File.read(cmd), cmd)
  end

  def test_command
    Appserver::Command.expects(:run!).with('doit', ['anarg', 'anotherarg'], {})
    appserver('doit', 'anarg', 'anotherarg')
  end

  def test_dir_option
    Appserver::Command.expects(:run!).with('doit', [], { :dir => '/path/to/anywhere' })
    appserver('--dir', '/path/to/anywhere', 'doit')
  end

  def test_force_option
    Appserver::Command.expects(:run!).with('doit', [], { :force => true })
    appserver('--force', 'doit')
  end
end
