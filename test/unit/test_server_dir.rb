require 'helper'

class TestServerDir < Test::Unit::TestCase

  def test_discover_raises_error_if_not_found
    in_empty_dir do
      assert_raise Appserver::NotInitializedError do
        Appserver::ServerDir.discover
      end
    end
  end

  def test_discover_finds_current_dir
    in_empty_dir do
      Appserver::ServerDir.init('.', :force => true)
      server_dir = Appserver::ServerDir.discover
      assert_kind_of Appserver::ServerDir, server_dir
      assert_equal Dir.pwd, server_dir.path
    end
  end

  def test_discover_finds_parent_dir
    in_empty_dir do
      Appserver::ServerDir.init('.', :force => true)
      Dir.mkdir('foo')
      Dir.chdir('foo') do
        server_dir = Appserver::ServerDir.discover
        assert_kind_of Appserver::ServerDir, server_dir
        assert_equal File.expand_path('..'), server_dir.path
      end
    end
  end

  def test_init_creates_config_file_and_subdirs
    in_empty_dir do
      assert_kind_of Appserver::ServerDir, Appserver::ServerDir.init('.', :force => true)
      assert File.exist?(Appserver::ServerDir::CONFIG_FILE_NAME)
      assert File.directory?('apps')
      assert File.directory?('tmp')
      assert File.directory?('log')
    end
  end

  def test_init_creates_directory
    in_empty_dir do
      assert_kind_of Appserver::ServerDir, Appserver::ServerDir.init('foo/bar/somewhere')
      assert File.exist?("foo/bar/somewhere/#{Appserver::ServerDir::CONFIG_FILE_NAME}")
      assert File.directory?('foo/bar/somewhere/apps')
    end
  end

  def test_init_fails_if_directory_exists
    in_empty_dir do
      Dir.mkdir('foo')
      assert_raise Appserver::DirectoryAlreadyExistError do
        Appserver::ServerDir.init('foo')
      end
    end
  end

  def test_init_works_if_directory_exists_but_forced
    in_empty_dir do
      Appserver::ServerDir.init('foo')
      assert_nothing_raised do
        assert_kind_of Appserver::ServerDir, Appserver::ServerDir.init('foo', :force => true)
      end
    end
  end

  def test_new_works_with_non_existing_directory
    in_empty_dir do
      assert_nothing_raised do
        Appserver::ServerDir.new('foo/bar')
        assert !File.exist?('foo')
      end
    end
  end

  def test_new_works_with_empty_config_file
    in_empty_dir do
      FileUtils.touch Appserver::ServerDir::CONFIG_FILE_NAME
      assert_nothing_raised do
        Appserver::ServerDir.new('.')
      end
    end
  end

  def test_app_creates_the_named_app_only_once
    in_server_dir do |server_dir|
      Appserver::App.expects(:new).returns(mock('app')).once
      assert_not_nil server_dir.app('foo')
      assert_not_nil server_dir.app('foo')
    end
  end

  def test_apps_returns_apps_for_every_normal_dir
    in_server_dir do |server_dir|
      ['apps/foo', 'apps/bar', 'apps/bar.old', 'apps/bar.new', 'apps/junk'].each do |path|
        create_dummy_rack_app(path)
      end
      assert_equal ['bar', 'foo', 'junk'], server_dir.apps.map { |app| app.name }.sort
    end
  end

  def test_repository_creates_the_named_repository_only_once
    in_server_dir do |server_dir|
      Appserver::Repository.expects(:new).returns(mock('repository')).once
      assert_not_nil server_dir.repository('/var/git/foo.git')
      assert_not_nil server_dir.repository('/var/git/foo.git')
    end
  end

  def test_write_configs
    in_server_dir do |server_dir|
      Appserver::Monit.expects(:write_config).with(server_dir)
      Appserver::Nginx.expects(:write_config).with(server_dir)
      Appserver::Logrotate.expects(:write_config).with(server_dir)
      server_dir.write_configs
    end
  end
end
