require 'helper'

class TestConfigurator < Test::Unit::TestCase

  DEFAULTS = {
    :alpha => 'aaa',
    :beta => 'bbb',
    :gamma => 'ccc',
    :delta => 'ddd',
  }

  CONFIG_TEXT = <<-EOF
    alpha 'anna'
    beta 'bob'
    context 'weird' do
      beta 'betty'
      gamma 'georg'
    end
  EOF

  class ConfigTarget < Struct.new(:alpha, :beta, :gamma, :delta)
    SETTINGS_DEFAULTS = DEFAULTS
    SETTINGS_EXPAND = []
  end

  def configurator (config_text, *args)
    config_file = '/tmp/some/path/test.conf.rb'
    File.stubs(:read).with(config_file).returns(config_text)
    Appserver::Configurator.new(config_file, *args)
  end

  def setup
    @config = configurator(CONFIG_TEXT)
  end

  def test_default_setting
    assert_no_match /delta/, CONFIG_TEXT
    @config.apply!(target = ConfigTarget.new)
    assert_equal DEFAULTS[:delta], target.delta
    @config.apply!(target = ConfigTarget.new, 'weird')
    assert_equal DEFAULTS[:delta], target.delta
    @config.apply!(target = ConfigTarget.new, 'away')
    assert_equal DEFAULTS[:delta], target.delta
  end

  def test_global_setting_is_global
    @config.apply!(target = ConfigTarget.new)
    assert_equal 'anna', target.alpha
    @config.apply!(target = ConfigTarget.new, 'weird')
    assert_equal 'anna', target.alpha
    @config.apply!(target = ConfigTarget.new, 'away')
    assert_equal 'anna', target.alpha
  end

  def test_context_setting_overrides_global_setting
    @config.apply!(target = ConfigTarget.new)
    assert_equal 'bob', target.beta
    @config.apply!(target = ConfigTarget.new, 'weird')
    assert_equal 'betty', target.beta
    @config.apply!(target = ConfigTarget.new, 'away')
    assert_equal 'bob', target.beta
  end

  def test_context_setting_overrides_default
    @config.apply!(target = ConfigTarget.new)
    assert_equal DEFAULTS[:gamma], target.gamma
    @config.apply!(target = ConfigTarget.new, 'weird')
    assert_equal 'georg', target.gamma
    @config.apply!(target = ConfigTarget.new, 'away')
    assert_equal DEFAULTS[:gamma], target.gamma
  end

  class ConfigTargetWithExpand < ConfigTarget
    SETTINGS_EXPAND = [ :beta, :gamma ]
    def path; '/tmp/some/path'; end
  end

  def test_settings_expand
    @config.apply!(target = ConfigTargetWithExpand.new)
    assert_equal 'anna', target.alpha
    assert_equal '/tmp/some/path/bob', target.beta
    assert_equal '/tmp/some/path/ccc', target.gamma
    assert_equal 'ddd', target.delta
  end

  def test_any_setting_is_possible_by_default
    config = configurator("alpha 'anna'; beta 'bob'")
    config.apply!(target = ConfigTarget.new)
    assert_equal 'anna', target.alpha
    assert_equal 'bob', target.beta
  end

  def test_allowed_global_settings
    assert_nothing_raised do
      configurator("alpha 'anna'; beta 'bob'", [ :alpha, :beta ])
    end
  end

  def test_allowed_global_settings_fail_on_invalid_setting
    assert_raise NoMethodError do
      configurator("alpha 'anna'; beta 'bob'", [ :alpha ])
    end
  end

  def test_allowed_context_settings
    assert_nothing_raised do
      configurator("context 'foo' do; alpha 'anna'; beta 'bob'; end", nil, [ :alpha, :beta ])
    end
  end

  def test_allowed_context_settings_fail_on_invalid_setting
    assert_raise NoMethodError do
      configurator("context 'foo' do; alpha 'anna'; beta 'bob'; end", nil, [ :alpha ])
    end
  end
end
