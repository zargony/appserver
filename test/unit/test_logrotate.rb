require 'helper'

class TestLogrotate < Test::Unit::TestCase

  def test_write_config
    in_server_dir do |server_dir|
      create_app('rack-simple', 'apps/hello')
      create_app('rack-simple', 'apps/hello2')
      assert !File.exist?('logrotate.conf')
      Appserver::Logrotate.write_config(server_dir)
      assert File.exist?('logrotate.conf')
    end
  end
end
