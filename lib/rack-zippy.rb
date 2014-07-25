require 'rack-zippy/version'

module Rack
  module Zippy

    PRECOMPILED_ASSETS_SUBDIR_REGEX = /\A\/assets(?:\/|\z)/

    class NullAssetCompiler
      def compiles?(path_info)
        return false
      end
    end

    class RailsAssetCompiler

      def initialize
        # config.assets.compile is normally false in production, and true in dev+test envs.
        # compile == true => active pipeline
        # compile == false => disabled pipeline
        @active = ::Rails.configuration.assets.compile
      end

      def compiles?(path_info)
        return active? && on_pipeline_path?(path_info)
      end

      private

      def on_pipeline_path?(path_info)
        path_info =~ PRECOMPILED_ASSETS_SUBDIR_REGEX
      end

      def active?
        return @active
      end

      def self.rails_env?
        return defined?(::Rails.version)
      end
    end

    class ServeableFile

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def self.find_all(options)
        path_info = options[:path_info]
        asset_root = options[:asset_root]
        file_path = options[:path]
        asset_compiler = options[:asset_compiler]

        serveable_files = []

        is_serveable = has_static_extension?(path_info) &&
            ::File.file?(file_path) &&
            ::File.readable?(file_path) &&
            !asset_compiler.compiles?(path_info)

        if is_serveable
          serveable_files << ServeableFile.new(file_path)
        end

        return serveable_files
      end

      def self.has_static_extension?(path)
        path =~ AssetServer::STATIC_EXTENSION_REGEX
      end

      def ==(other)
        return false if other.nil?
        return true if self.equal?(other)
        return self.class == other.class && self.path == other.path
      end
      alias_method :eql?, :==

    end

    class AssetServer

      # Font extensions: woff, woff2, ttf, eot, otf
      STATIC_EXTENSION_REGEX = /\.(?:css|js|html|htm|txt|ico|png|jpg|jpeg|gif|pdf|svg|zip|gz|eps|psd|ai|woff|woff2|ttf|eot|otf|swf)\z/i

      def initialize(app, asset_root=nil)
        if asset_root.nil?
          if RailsAssetCompiler.rails_env?
            asset_root = ::Rails.public_path
          else
            raise ArgumentError.new 'Please specify asset_root when initializing Rack::Zippy::AssetServer ' +
              '(asset_root is the path to your public directory, often the one with favicon.ico in it)'
          end
        end
        @app = app
        @asset_root = asset_root
        @asset_compiler = resolve_asset_compiler
      end

      def call(env)
        path_info = env['PATH_INFO']
        assert_legal_path path_info

        file_path = path_to_file(path_info)

        serveable_files = ServeableFile.find_all(
            :path_info => path_info,
            :asset_root => @asset_root,
            :path => file_path,
            :asset_compiler => @asset_compiler
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

      def path_to_file(path_info)
        "#{@asset_root}#{path_info}"
      end

      def client_accepts_gzip?(rack_env)
        rack_env['HTTP_ACCEPT_ENCODING'] =~ ACCEPTS_GZIP_REGEX
      end

      def assert_legal_path(path_info)
        raise SecurityError.new('Illegal path requested') if path_info =~ ILLEGAL_PATH_REGEX
      end

      def resolve_asset_compiler
        asset_compiler_class = RailsAssetCompiler.rails_env? ? RailsAssetCompiler : NullAssetCompiler
        return asset_compiler_class.new
      end

    end
  end
end
