require 'rack-zippy/version'

module Rack
  module Zippy

    PRECOMPILED_ASSETS_SUBDIR_REGEX = /\A\/assets(?:\/|\z)/

    class ServeableFile

      # Font extensions: woff, woff2, ttf, eot, otf
      STATIC_EXTENSION_REGEX = /\.(?:css|js|html|htm|txt|ico|png|jpg|jpeg|gif|pdf|svg|zip|gz|eps|psd|ai|woff|woff2|ttf|eot|otf|swf)\z/i

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def self.find_all(options)
        path_info = options[:path_info]
        asset_root = options[:asset_root]
        file_path = options[:path]

        serveable_files = []

        if has_static_extension?(path_info)
          is_serveable = ::File.file?(file_path) && ::File.readable?(file_path)

          if is_serveable
            is_outside_assets_dir = !(path_info =~ ::Rack::Zippy::PRECOMPILED_ASSETS_SUBDIR_REGEX)
            if is_outside_assets_dir || block_asset_pipeline_from_generating_asset?
              serveable_files << ServeableFile.new(file_path)
            end
          end
        end

        return serveable_files
      end

      def self.has_static_extension?(path)
        path =~ STATIC_EXTENSION_REGEX
      end

      def self.block_asset_pipeline_from_generating_asset?
        # config.assets.compile is normally false in production, and true in dev+test envs.
        !::Rails.configuration.assets.compile
      end

      def ==(other)
        return false if other.nil?
        return true if self.equal?(other)
        return self.class == other.class && self.path == other.path
      end
      alias_method :eql?, :==

    end

    class AssetServer

      def initialize(app, asset_root=Rails.public_path)
        @app = app
        @asset_root = asset_root
      end

      def call(env)
        path_info = env['PATH_INFO']
        assert_legal_path path_info

        file_path = path_to_file(path_info)

        serveable_files = ServeableFile.find_all(
            :path_info => path_info,
            :asset_root => @asset_root,
            :path => file_path
        )

        unless serveable_files.empty?
          headers = { 'Content-Type'  => Rack::Mime.mime_type(::File.extname(path_info)) }
          headers.merge! cache_headers(path_info)

          gzipped_file_path = "#{file_path}.gz"
          gzipped_file_present = ::File.exists?(gzipped_file_path) && ::File.readable?(gzipped_file_path)

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

      ACCEPTS_GZIP_REGEX = /\bgzip\b/

      ILLEGAL_PATH_REGEX = /(\.\.|\/\.)/

      # Old last-modified headers encourage caching via browser heuristics. Use it for year-long cached assets.
      CACHE_FRIENDLY_LAST_MODIFIED = 'Mon, 10 Jan 2005 10:00:00 GMT'

      def cache_headers(path_info)
        case path_info
          when ::Rack::Zippy::PRECOMPILED_ASSETS_SUBDIR_REGEX
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

      def path_to_file(path_info)
        "#{@asset_root}#{path_info}"
      end

      def client_accepts_gzip?(rack_env)
        rack_env['HTTP_ACCEPT_ENCODING'] =~ ACCEPTS_GZIP_REGEX
      end

      def assert_legal_path(path_info)
        raise SecurityError.new('Illegal path requested') if path_info =~ ILLEGAL_PATH_REGEX
      end

    end
  end
end
