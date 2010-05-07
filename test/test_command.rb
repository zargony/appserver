require 'helper'
require 'appserver/command'

class TestCommand < Test::Unit::TestCase

  def setup
    @app = stub('app', :branch => 'thebranch')
    @repository = stub('repository', :app => @app)
    @server_dir = stub('server_dir', :repository => @repository)
    Appserver::ServerDir.stubs(:new => @server_dir)
  end

  def test_unknown_command
    assert_raise Appserver::UnknownCommandError do
      Appserver::Command.run!('foo', [])
    end
  end

  def test_init
    Appserver::ServerDir.expects(:initialize_dir)
    @server_dir.expects(:write_configs)
    Appserver::Command.run!('init', [])
  end

  def test_update
    @server_dir.expects(:write_configs)
    Appserver::Command.run!('update', [])
  end

  def test_deploy_manually
    @server_dir.expects(:repository).with('repo.git').returns(@repository)
    @repository.expects(:install_hook)
    @repository.expects(:deploy).with('thebranch')
    Appserver::Command.run!('deploy', ['repo.git'])
  end

  def test_deploy_on_update
    @server_dir.expects(:repository).with('repo.git').returns(@repository)
    @repository.expects(:install_hook)
    @repository.expects(:deploy).with('0123456789abcdef')
    Appserver::Command.run!('deploy', ['repo.git', '/refs/heads/thebranch', '0123456789abcdef'])
  end

  def test_deploy_on_update_of_different_branch_does_nothing
    @server_dir.expects(:repository).with('repo.git').returns(@repository)
    @repository.expects(:install_hook)
    @repository.expects(:deploy).never
    Appserver::Command.run!('deploy', ['repo.git', '/refs/heads/xyz', '0123456789abcdef'])
  end
end
