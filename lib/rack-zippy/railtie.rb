module Rack
  module Zippy
    class Railtie < ::Rails::Railtie

      cattr_accessor :skip_version_check

      def self.version_check
        return if Rack::Zippy::Railtie.skip_version_check
        if ::Rails.version.to_f >= minimum_rails_version_with_gzip_serving
          puts "[rack-zippy] rack-zippy is not supported for this version of Rails. Rails now supports serving gzipped files using its own ActionDispatch::Static middleware. It is strongly recommended you remove rack-zippy from your app and use ActionDispatch::Static in its place."
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
