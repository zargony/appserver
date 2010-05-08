require 'helper'

class TestNginx < Test::Unit::TestCase

  def test_write_config
    in_server_dir do |server_dir|
      create_dummy_rack_app('apps/hello')
      assert !File.exist?('nginx.conf')
      Appserver::Nginx.write_config(server_dir)
      assert File.exist?('nginx.conf')
    end
  end
end
