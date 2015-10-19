require_relative 'test_helper'

module Rails
  class Railtie
    def self.config
      OpenStruct.new(after_initialize: true)
    end
  end

  def self.version
    raise 'Stub Rails.version'
  end
end

require 'rack-zippy/railtie'

module Rack
  module Zippy
    class RailtieTest <  TestCase

      def teardown
        Rack::Zippy::Railtie.skip_version_check = false
      end

      def test_upgrade_rails_or_downgrade_zippy_recommendation_for_rails_versions_below_4_2
        with_rails_version('4.1.99') do
          assert_output("[rack-zippy] This version of rack-zippy does not support Rails. Your choices include: 1) [RECOMMENDED] Upgrade to Rails 4.2 or above and use Rails' built-in ActionDispatch::Static middleware to serve gzipped files. or 2) Specify an earlier version of rack-zippy (~> '3.0.1') in your Gemfile that does support Rails\n") { Rack::Zippy::Railtie.version_check }
        end
      end

      versions = ['4.2.0', '5.0.0', '10.0.0']
      versions.each do |version|
        test "remove zippy recommendation printed for Rails versions #{version}" do
            with_rails_version(version) do
              assert_output("[rack-zippy] rack-zippy is not supported for this version of Rails. Rails now supports serving gzipped files using its own ActionDispatch::Static middleware. It is strongly recommended you remove rack-zippy from your app and use ActionDispatch::Static in its place.\n") { Rack::Zippy::Railtie.version_check }
            end
        end
      end

      def test_config_silences_remove_zippy_recommendation_for_rails_versions_4_2_and_above
        versions = ['4.2.0', '5.0.0', '10.0.0']
        versions.each do |version|
          with_rails_version(version) do
            Rack::Zippy::Railtie.skip_version_check = true
            assert_silent { Rack::Zippy::Railtie.version_check }
          end
        end
      end

      private

      def with_rails_version(version)
        Rails.stub :version, version do
          yield
        end
      end

    end
  end
end
