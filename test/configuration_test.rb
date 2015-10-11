require_relative 'test_helper'
require 'rack-zippy/configuration'

module Rack
  module Zippy
    class ConfigurationTest < TestCase

      def setup
        Rack::Zippy.const_set(:ConfiguredClass, Class.new)
        ConfiguredClass.extend Configuration
      end

      def teardown
        Rack::Zippy.send(:remove_const, :ConfiguredClass)
      end


      def setting_name
        'test_setting'
      end

      def test_define_setting_create_setter_method
        ConfiguredClass.define_setting setting_name
        assert ConfiguredClass.respond_to? "#{setting_name}="
      end

      def test_define_setting_create_getter_method
        ConfiguredClass.define_setting setting_name
        assert ConfiguredClass.respond_to? setting_name
      end

      def test_define_setting_create_reset_method
        ConfiguredClass.define_setting setting_name
        assert ConfiguredClass.respond_to? "reset_#{setting_name}"
      end

      def test_define_setting_can_handle_not_clonable_default_values
        ConfiguredClass.define_setting setting_name, :singleton_type_instance
        assert_equal ConfiguredClass.test_setting, :singleton_type_instance
      end

      def test_reset_setting_to_default_value
        ConfiguredClass.define_setting 'test_setting', 'default_value'
        ConfiguredClass.test_setting = 'new_value'
        ConfiguredClass.reset_test_setting
        assert_equal ConfiguredClass.test_setting, 'default_value'
      end

      def test_setter_store_config_value
        ConfiguredClass.define_setting 'test_setting', 'default_value'
        ConfiguredClass.test_setting = 'new_value'
        assert_equal ConfiguredClass.test_setting, 'new_value'
      end

      def test_reset_setting_if_default_value_passed_by_reference
        ConfiguredClass.define_setting 'test_setting', [1]
        ConfiguredClass.test_setting << 2
        ConfiguredClass.reset_test_setting
        assert_equal ConfiguredClass.test_setting, [1]
      end
    end
  end
end
