require 'rack-zippy/version'
require 'rack-zippy/asset_compiler'
require 'rack-zippy/serveable_file'

module Rack
  module Zippy

    PRECOMPILED_ASSETS_SUBDIR_REGEX = /\A\/assets(?:\/|\z)/

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

        serveable_file = ServeableFile.find_first(
            :path_info => path_info,
            :asset_root => @asset_root,
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
