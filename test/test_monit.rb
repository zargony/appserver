require 'helper'
require 'appserver/monit'

class TestMonit < Test::Unit::TestCase

  def test_write_config
    in_server_dir do |server_dir|
      create_dummy_rack_app('apps/hello')
      assert !File.exist?('monitrc')
      Appserver::Monit.write_config(server_dir)
      assert File.exist?('monitrc')
    end
  end
end
