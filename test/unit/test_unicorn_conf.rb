require 'helper'
require 'unicorn'
require 'etc'

class TestUnicornConf < Test::Unit::TestCase

  def test_unicorn_configuration
    in_server_dir do |server_dir|
      create_dummy_rack_app('apps/hello')
      app = server_dir.app('hello')
      Appserver::App.any_instance.expects(:user => Etc.getlogin).at_least_once
      Appserver::App.any_instance.expects(:setup_env!)
      Unicorn::Configurator.any_instance.expects(:working_directory).with(app.path)
      Unicorn::Configurator.any_instance.expects(:stderr_path).with(app.server_log)
      Unicorn::Configurator.any_instance.expects(:stdout_path).with(app.server_log)
      Unicorn::Configurator.any_instance.expects(:pid).with(app.pid_file)
      Unicorn::Configurator.any_instance.expects(:listen).with('unix:' + app.socket, :backlog => 64)
      Unicorn::Configurator.any_instance.expects(:user).with(app.user, app.group)
      Unicorn::Configurator.any_instance.expects(:worker_processes).with(app.instances)
      Unicorn::Configurator.any_instance.expects(:preload_app).with(app.preload)
      Unicorn::Configurator.any_instance.expects(:timeout).with(30)
      Unicorn::Configurator.any_instance.expects(:before_fork)
      Unicorn::Configurator.any_instance.expects(:after_fork)
      Unicorn::HttpServer::START_CTX[:argv] = [app.rack_config]
      Unicorn::HttpServer.new(Unicorn.builder(app.rack_config, {}), :config_file => app.unicorn_config)
    end
  end

  def wait_unicorn_ready (app)
    50.times do
      return if File.exist?(app.server_log) && File.readlines(app.server_log).grep(/master process ready/)[0]
      sleep 0.2
    end
    raise 'Unicorn did not become ready'
  end

  def assert_shutdown (pid)
    assert_nothing_raised { Process.kill(:TERM, pid) }
    status = nil
    assert_nothing_raised { pid, status = Process.waitpid2(pid) }
    assert status.success?, 'exited successfully'
  end

  def test_unicorn_server
    in_server_dir do |server_dir|
      create_dummy_rack_app('apps/hello')
      app = server_dir.app('hello')
      pid = fork { exec app.start_cmd }
      wait_unicorn_ready(app)
      UNIXSocket.open(app.socket) do |s|
        s.write "GET / HTTP/1.1\r\n\r\n"
        response = s.readlines
        assert_match /^HTTP\/1.1 200 /, response[0]
      end
      assert_shutdown(pid)
    end
  end
end
