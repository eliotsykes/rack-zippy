require "rack-zippy/version"

module Rack
  module Zippy
    class AssetServer

      def initialize(app, asset_root='public')
        @app = app
        @asset_root = asset_root
      end

      def call(env)
        path_info = env['PATH_INFO']
        assert_legal_path path_info

        if has_static_extension?(path_info)
          file_path = "#{@asset_root}#{path_info}"

          if ::File.exists?(file_path)
            status = 200
            headers = {
              'Content-Length' => ::File.size(file_path).to_s,
              'Content-Type'  => Rack::Mime.mime_type(::File.extname(file_path)),
              'Last-Modified' => 'Mon, 10 Jan 2005 10:00:00 GMT',
              'Cache-Control' => "public, max-age=#{max_age_in_secs(path_info)}"
            }
            response_body = [::File.read(file_path)]
            return [status, headers, response_body]
          else
            status = 404
            headers = {}
            response_body = ['Not Found']
            return [status, headers, response_body]
          end
        end

        @app.call(env)
      end

      private

      SECONDS_IN = {
          :day => 24*60*60,
          :month => 31*(24*60*60),
          :year => 365*(24*60*60)
      }.freeze

      STATIC_EXTENSION_REGEX = /\.(?:css|js|html|htm|txt|ico|png|jpg|jpeg|gif|pdf|svg|zip|gz|eps|psd|ai)\z/i

      ASSETS_SUBDIR_REGEX = /\A\/assets\//

      def max_age_in_secs(path_info)
        case path_info
          when ASSETS_SUBDIR_REGEX
            max_age = SECONDS_IN[:year]
          when '/favicon.ico'
            max_age = SECONDS_IN[:month]
          else
            max_age = SECONDS_IN[:day]
        end

        return max_age
      end

      def has_static_extension?(path)
        path =~ STATIC_EXTENSION_REGEX
      end

      def assert_legal_path(path_info)
        raise SecurityError.new('Illegal path requested') if path_info.include?('..')
      end

    end
  end
end
