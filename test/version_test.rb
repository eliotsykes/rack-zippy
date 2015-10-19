require_relative 'test_helper'
require 'minitest/autorun'
require 'rack-zippy/version'

module Rack
  module Zippy
    class VersionTest <  Minitest::Test

      def test_no_remove_zippy_recommendation_for_non_rails_apps
        assert_silent { Rack::Zippy.version_check }
      end

      def test_no_remove_zippy_recommendation_for_rails_versions_below_4_2
        assert_silent { version_check }
        stub Rails.version with "4.1.99"
        flunk
      end

      def test_remove_zippy_recommendation_for_rails_versions_4_2_and_above
        stub Rails.version with "4.2.0", "5.0.0"
        flunk
      end

      def test_config_silences_remove_zippy_recommendation_for_rails_versions_4_2_and_above
        # Use Rack::Zippy.configuration
        flunk
      end

    end
  end
end
