module Rack
  module Zippy
    class Railtie < ::Rails::Railtie

      def self.version_check
        # return if defined?(Rack::Zippy.skip_rails_version_check)
        if ::Rails.version >= minimum_rails_version_with_gzip_serving
          puts "Oh no!!!!!!!!!"
        end
      end

      def self.minimum_rails_version_with_gzip_serving
        "4.2"
      end

    end
  end
end
