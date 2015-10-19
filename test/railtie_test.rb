require_relative 'test_helper'

module Rails
  class Railtie
  end

  def self.version
    raise 'Stub Rails.version'
  end
end

require 'rack-zippy/railtie'

module Rack
  module Zippy
    class RailtieTest <  TestCase

      def test_no_remove_zippy_recommendation_for_rails_versions_below_4_2
        with_rails_version('4.1.99') do
          assert_silent { Rack::Zippy::Railtie.version_check }
        end
      end

      versions = ['4.2.0', '5.0.0', '10.0.0']
      versions.each do |version|
        test "remove zippy recommendation printed for Rails versions #{version}" do
            with_rails_version(version) do
              assert_output("rack-zippy is not recommended for this version of Rails. Rails now supports serving gzipped files using its own ActionDispatch::Static middleware. Please remove rack-zippy from your app.\n") { Rack::Zippy::Railtie.version_check }
            end
        end
      end


      def test_config_silences_remove_zippy_recommendation_for_rails_versions_4_2_and_above
        # Look at Railties and delay version check to later in startup
        # def Rack::Zippy.skip_rails_version_check = ->() { true }
        # Rack::Zippy.skip_rails_version_check
        versions = ['4.2.0', '5.0.0', '10.0.0']
        versions.each do |version|
          with_rails_version(version) do
            assert_silent { Rack::Zippy::Railtie.version_check }
          end
        end
      ensure
        # class << Rack::Zippy
        #   remove_method :skip_rails_version_check
        # end
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
