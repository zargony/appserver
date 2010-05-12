require 'helper'

class TestRepository < Test::Unit::TestCase

  def setup
    # FIXME: This is currently needed to silence appserver output during tests :(
    Appserver::Repository.any_instance.stubs(:puts)
  end

  def test_valid
    in_server_dir do |server_dir|
      create_app_repo 'rack-simple', 'hello.git'
      repo = Appserver::Repository.new(server_dir, 'hello.git', {})
      assert repo.valid?
    end
  end

  def test_install_hook
    in_server_dir do |server_dir|
      create_app_repo 'rack-simple', 'hello.git'
      repo = Appserver::Repository.new(server_dir, 'hello.git', {})
      repo.install_hook
      assert File.executable?('hello.git/hooks/update')
      assert File.readlines('hello.git/hooks/update').grep(/appserver.*deploy/).size == 1
      repo.install_hook # Try it a second time
    end
  end

  def test_deploy
    in_server_dir do |server_dir|
      create_app_repo 'rack-simple', 'hello.git'
      repo = Appserver::Repository.new(server_dir, 'hello.git', {})
      assert !server_dir.app('hello').exist?
      repo.deploy
      assert server_dir.app('hello').exist? && server_dir.app('hello').rack?
      repo.deploy # Try it a second time
    end
  end

  def test_deploy_with_gemfile
    in_server_dir do |server_dir|
      create_app_repo 'sinatra', 'hello.git'
      repo = Appserver::Repository.new(server_dir, 'hello.git', {})
      repo.expects(:system).with { |cmd| cmd =~ /bundle install/ }.at_least_once
      repo.deploy
      assert File.exist?(server_dir.app('hello').gem_file)
      repo.deploy # Try it a second time
    end
  end
end
