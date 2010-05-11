require 'helper'
require 'socket'

class TestUtils < Test::Unit::TestCase

  def test_find_in_path
    Appserver::Utils.send(:const_set, :ENV, 'PATH' => '/some/where/bin:/no/where/bin:/home/foo/bin')
    File.stubs(:executable?).returns(false)
    File.expects(:executable?).with('/home/foo/bin/theapp').returns(true)
    assert_equal '/home/foo/bin/theapp', Appserver::Utils.find_in_path('theapp')
    Appserver::Utils.send(:remove_const, :ENV)
  end

  def test_find_in_path_fails
    Appserver::Utils.send(:const_set, :ENV, 'PATH' => '/some/where/bin:/no/where/bin:/home/foo/bin')
    File.expects(:executable?).returns(false).at_least_once
    assert_nil Appserver::Utils.find_in_path('theapp')
    Appserver::Utils.send(:remove_const, :ENV)
  end

  def test_system_hostname
    Socket.expects(:gethostname).returns('foo.bar.net')
    assert_equal 'foo.bar.net', Appserver::Utils.system_hostname
  end

  def test_system_domainname
    Appserver::Utils.expects(:system_hostname).returns('foo.bar.net')
    assert_equal 'bar.net', Appserver::Utils.system_domainname
  end

  def test_number_of_cpus
    File.stubs(:exist?).with('/proc/cpuinfo').returns(true)
    File.expects(:readlines).with('/proc/cpuinfo').returns(["processor : 0\n", "processor : 1\n"])
    assert_equal 2, Appserver::Utils.number_of_cpus.to_i
  end
end
