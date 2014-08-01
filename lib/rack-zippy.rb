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

    # TODO: Move ServeableFile to serveable_file.rb
    class ServeableFile

      attr_reader :path, :path_info

      def initialize(options)
        raise ArgumentError.new(':has_encoding_variants option must be given') unless options.has_key?(:has_encoding_variants)

        @path = options[:path]
        @path_info = options[:path_info]
        @has_encoding_variants = options[:has_encoding_variants]
        @is_gzipped = options[:is_gzipped]
      end

      def headers
        headers = { 'Content-Type'  => Rack::Mime.mime_type(::File.extname(path_info)) }
        headers.merge! cache_headers

        headers['Vary'] = 'Accept-Encoding' if encoding_variants?
        headers['Content-Encoding'] = 'gzip' if gzipped?

        headers['Content-Length'] = ::File.size(path).to_s
        return headers
      end

      def cache_headers
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

      def response_body
        [::File.read(path)]
      end

      def self.find_first(options)
        path_info = options[:path_info]
        asset_compiler = options[:asset_compiler]

        is_path_info_serveable = has_static_extension?(path_info) && !asset_compiler.compiles?(path_info)

        if !is_path_info_serveable
          return nil
        end

        asset_root = options[:asset_root]
        file_path = options[:path]
        include_gzipped = options[:include_gzipped]

        gzipped_file_path = "#{file_path}.gz"
        gzipped_file_present = ::File.file?(gzipped_file_path) && ::File.readable?(gzipped_file_path)

        has_encoding_variants = gzipped_file_present

        if include_gzipped && gzipped_file_present
          return ServeableFile.new(
              :path => gzipped_file_path,
              :path_info => path_info,
              :has_encoding_variants => has_encoding_variants,
              :is_gzipped => true
          )
        end

        is_serveable = ::File.file?(file_path) && ::File.readable?(file_path)

        if is_serveable
          return ServeableFile.new(
              :path => file_path,
              :path_info => path_info,
              :has_encoding_variants => has_encoding_variants
          )
        end

        return nil
      end

      def self.has_static_extension?(path)
        path =~ AssetServer::STATIC_EXTENSION_REGEX
      end

      def encoding_variants?
        return @has_encoding_variants
      end

      def gzipped?
        return @is_gzipped
      end

      def ==(other)
        return false if other.nil?
        return true if self.equal?(other)
        return self.class == other.class &&
          self.gzipped? == other.gzipped? &&
          self.encoding_variants? == other.encoding_variants? &&
          self.path == other.path &&
          self.path_info == other.path_info
      end
      alias_method :eql?, :==

      private

      # Old last-modified headers encourage caching via browser heuristics. Use it for year-long cached assets.
      CACHE_FRIENDLY_LAST_MODIFIED = 'Mon, 10 Jan 2005 10:00:00 GMT'

      SECONDS_IN = {
          :day => 24*60*60,
          :month => 31*(24*60*60),
          :year => 365*(24*60*60)
      }.freeze

    end

    class AssetServer

      # Font extensions: woff, woff2, ttf, eot, otf
      STATIC_EXTENSION_REGEX = /\.(?:css|js|html|htm|txt|ico|png|jpg|jpeg|gif|pdf|svg|zip|gz|eps|psd|ai|woff|woff2|ttf|eot|otf|swf)\z/i

      HTTP_STATUS_CODE_OK = 200.freeze

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

        serveable_file = ServeableFile.find_first(
            :path_info => path_info,
            :asset_root => @asset_root,
            :path => file_path,
            :asset_compiler => @asset_compiler,
            :include_gzipped => client_accepts_gzip?(env)
        )

        if serveable_file
          return [HTTP_STATUS_CODE_OK, serveable_file.headers, serveable_file.response_body]
        end

        @app.call(env)
      end

      private

      ACCEPTS_GZIP_REGEX = /\bgzip\b/

      ILLEGAL_PATH_REGEX = /(\.\.|\/\.)/

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
