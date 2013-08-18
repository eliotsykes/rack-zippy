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

        if has_static_extension?(path_info)
          file_path = "#{@asset_root}#{path_info}"

          if ::File.exists?(file_path)
            status = 200
            headers = {
              'Content-Length' => ::File.size(file_path).to_s,
              'Content-Type'   => Rack::Mime.mime_type(::File.extname(file_path))
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

      STATIC_EXTENSION_REGEX = /\.(?:css|js|html|htm|txt|ico|png|jpg|jpeg|gif|pdf|svg|zip|gz|eps|psd|ai)\z/i

      def has_static_extension?(path)
        path =~ STATIC_EXTENSION_REGEX
      end

    end
  end
end
