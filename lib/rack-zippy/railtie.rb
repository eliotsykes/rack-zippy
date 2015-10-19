module Rack
  module Zippy
    class Railtie < ::Rails::Railtie

      def self.version_check
        # return if defined?(Rack::Zippy.skip_rails_version_check)
        if ::Rails.version.to_f >= minimum_rails_version_with_gzip_serving
          puts "rack-zippy is not recommended for this version of Rails. Rails now supports serving gzipped files using its own ActionDispatch::Static middleware. Please remove rack-zippy from your app."
        end
      end

      def self.minimum_rails_version_with_gzip_serving
        4.2
      end

    end
  end
end
