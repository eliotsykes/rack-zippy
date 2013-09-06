require 'rack-zippy/version'

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

        if serve?(path_info)

          file_path = "#{@asset_root}#{path_info}"

          if ::File.file?(file_path)
            headers = { 'Content-Type'  => Rack::Mime.mime_type(::File.extname(path_info)) }
            headers.merge! cache_headers(path_info)

            gzipped_file_path = "#{file_path}.gz"
            gzipped_file_present = ::File.exists?(gzipped_file_path)

            if gzipped_file_present
              headers['Vary'] = 'Accept-Encoding'

              if client_accepts_gzip?(env)
                file_path = gzipped_file_path
                headers['Content-Encoding'] = 'gzip'
              end
            end

            status = 200
            headers['Content-Length'] = ::File.size(file_path).to_s
            response_body = [::File.read(file_path)]
          else
            status = 404
            headers = {}
            response_body = ['Not Found']
          end
          return [status, headers, response_body]
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

      PRECOMPILED_ASSETS_SUBDIR_REGEX = /\A\/assets(?:\/|\z)/

      ACCEPTS_GZIP_REGEX = /\bgzip\b/

      ILLEGAL_PATH_REGEX = /(\.\.|\/\.)/

      # Old last-modified headers encourage caching via browser heuristics. Use it for year-long cached assets.
      CACHE_FRIENDLY_LAST_MODIFIED = 'Mon, 10 Jan 2005 10:00:00 GMT'

      def cache_headers(path_info)
        case path_info
          when PRECOMPILED_ASSETS_SUBDIR_REGEX
            lifetime = :year
            last_modified = CACHE_FRIENDLY_LAST_MODIFIED
          when '/favicon.ico'
            lifetime = :month
            last_modified = CACHE_FRIENDLY_LAST_MODIFIED
          else
            lifetime = :day
        end

        headers = { 'Cache-Control' => "public, max-age=#{SECONDS_IN[lifetime]}" }
        headers['Last-Modified'] = last_modified if last_modified

        return headers
      end

      def serve?(path_info)
        is_assets_dir_or_below = (path_info =~ PRECOMPILED_ASSETS_SUBDIR_REGEX)
        if is_assets_dir_or_below
          return should_assets_be_compiled_already?
        end
        return has_static_extension?(path_info)
      end

      def should_assets_be_compiled_already?
        !::Rails.configuration.assets.compile
      end

      def client_accepts_gzip?(rack_env)
        rack_env['HTTP_ACCEPT_ENCODING'] =~ ACCEPTS_GZIP_REGEX
      end

      def has_static_extension?(path)
        path =~ STATIC_EXTENSION_REGEX
      end

      def assert_legal_path(path_info)
        raise SecurityError.new('Illegal path requested') if path_info =~ ILLEGAL_PATH_REGEX
      end

    end
  end
end
