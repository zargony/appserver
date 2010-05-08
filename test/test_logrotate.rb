require 'helper'
require 'appserver/logrotate'

class TestLogrotate < Test::Unit::TestCase

  def test_write_config
    in_server_dir do |server_dir|
      create_dummy_rack_app('apps/hello')
      assert !File.exist?('logrotate.conf')
      Appserver::Logrotate.write_config(server_dir)
      assert File.exist?('logrotate.conf')
    end
  end
end
