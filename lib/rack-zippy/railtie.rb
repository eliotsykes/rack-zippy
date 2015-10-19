module Rack
  module Zippy
    class Railtie < ::Rails::Railtie

      cattr_accessor :skip_version_check

      def self.version_check
        return if Rack::Zippy::Railtie.skip_version_check
        if ::Rails.version.to_f >= minimum_rails_version_with_gzip_serving
          puts "[rack-zippy] rack-zippy is not supported for this version of Rails. Rails now supports serving gzipped files using its own ActionDispatch::Static middleware. It is strongly recommended you remove rack-zippy from your app and use ActionDispatch::Static in its place."
        else
          puts "[rack-zippy] This version of rack-zippy does not support Rails. Your choices include: 1) [RECOMMENDED] Upgrade to Rails #{minimum_rails_version_with_gzip_serving} or above and use Rails' built-in ActionDispatch::Static middleware to serve gzipped files. or 2) Specify an earlier version of rack-zippy (~> '3.0.1') in your Gemfile that does support Rails"
        end
      end

      def self.minimum_rails_version_with_gzip_serving
        4.2
      end

      config.after_initialize do
        Rack::Zippy::Railtie.version_check
      end

    end
  end
end
