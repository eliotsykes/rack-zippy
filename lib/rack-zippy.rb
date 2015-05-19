require 'rack-zippy/version'
require 'rack-zippy/asset_compiler'
require 'rack-zippy/serveable_file'
require 'rack-zippy/configuration'

module Rack
  module Zippy
    extend Configuration

    define_setting :static_extensions, %w(css js html htm txt ico png jpg jpeg gif pdf svg zip gz eps psd ai woff woff2 ttf eot otf swf)

    PRECOMPILED_ASSETS_SUBDIR_REGEX = /\A\/assets(?:\/|\z)/

    class AssetServer

      HTTP_STATUS_CODE_OK = 200

      def initialize(app, asset_root=nil, options={})
        if asset_root.nil?
          if RailsAssetCompiler.rails_env?
            asset_root = ::Rails.public_path
          else
            raise ArgumentError.new 'Please specify asset_root when initializing Rack::Zippy::AssetServer ' +
              '(asset_root is the path to your public directory, often the one with favicon.ico in it)'
          end
        end
        @app = app

        @options = {
          :asset_compiler => resolve_asset_compiler,
          :asset_root => asset_root
        }.merge(options)
      end

      def call(env)
        path_info = env['PATH_INFO']

        return not_found_response if path_info =~ ILLEGAL_PATH_REGEX

        serveable_file_options = {
            :path_info => path_info,
            :asset_root => asset_root,
            :asset_compiler => asset_compiler,
            :include_gzipped => client_accepts_gzip?(env),
            :max_age_fallback => @options[:max_age_fallback]
        }

        serveable_file = ServeableFile.find_first(serveable_file_options)


        if serveable_file
          return [HTTP_STATUS_CODE_OK, serveable_file.headers, serveable_file.response_body]
        end

        @app.call(env)
      end

      def asset_root
        @options[:asset_root]
      end

      private

      ACCEPTS_GZIP_REGEX = /\bgzip\b/

      ILLEGAL_PATH_REGEX = /(\/\.\.?)/

      def client_accepts_gzip?(rack_env)
        rack_env['HTTP_ACCEPT_ENCODING'] =~ ACCEPTS_GZIP_REGEX
      end

      def resolve_asset_compiler
        asset_compiler_class = RailsAssetCompiler.rails_env? ? RailsAssetCompiler : NullAssetCompiler
        return asset_compiler_class.new
      end

      def asset_compiler
        @options[:asset_compiler]
      end

      def not_found_response
        [404, {}, ['Not Found']]
      end

    end
  end
end
