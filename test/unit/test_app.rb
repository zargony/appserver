require 'helper'
require 'bundler'

class TestApp < Test::Unit::TestCase

  def setup
    @env = { 'PATH' => '/some/where:/no/where', 'FOO_KEY' => 'FooFoo', 'MY_DIR' => '/no/where' }
    Appserver::App.send(:const_set, :ENV, @env)
  end

  def teardown
    Appserver::App.send(:remove_const, :ENV)
  end

  def test_default_hostname
    in_server_dir do |server_dir|
      Appserver::App::SETTINGS_DEFAULTS[:domain] = 'example.com'
      app = server_dir.app('myapp')
      assert_equal 'example.com', app.domain
      assert_equal 'myapp.example.com', app.hostname
    end
  end

  def test_setup_env_default_environment
    in_server_dir do |server_dir|
      app = server_dir.app('myapp')
      assert_equal([], app.env_whitelist)
      assert_equal({}, app.env)
      app.setup_env!
      assert_equal({ 'PATH' => '/some/where:/no/where' }, @env)
    end
  end

  def test_setup_env_whitelist
    in_server_dir do |server_dir|
      app = server_dir.app('myapp')
      app.stubs(:env_whitelist => ['MY_DIR'])
      app.setup_env!
      assert_equal({ 'PATH' => '/some/where:/no/where', 'MY_DIR' => '/no/where' }, @env)
    end
  end

  def test_setup_env_full_environment
    in_server_dir do |server_dir|
      app = server_dir.app('myapp')
      app.stubs(:env_whitelist => '*')
      app.setup_env!
      assert_equal({ 'PATH' => '/some/where:/no/where', 'FOO_KEY' => 'FooFoo', 'MY_DIR' => '/no/where' }, @env)
    end
  end

  def test_setup_env_additions
    in_server_dir do |server_dir|
      app = server_dir.app('myapp')
      app.stubs(:env => { 'SOME_KEY' => 'secret' })
      app.setup_env!
      assert_equal({ 'PATH' => '/some/where:/no/where', 'SOME_KEY' => 'secret' }, @env)
    end
  end

  def test_setup_env_sets_up_gem_bundle
    in_server_dir do |server_dir|
      app = server_dir.app('myapp')
      File.stubs(:exist?).with(app.gem_file).returns(true)
      File.stubs(:directory?).with(app.bundle_path).returns(true)
      app.setup_env!
      assert_not_nil @env['BUNDLE_PATH']
      assert_not_nil @env['GEM_HOME']
    end
  end
end
