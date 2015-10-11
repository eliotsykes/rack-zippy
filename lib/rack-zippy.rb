require 'rack-zippy/version'
require 'action_controller'

module Rack
  module Zippy
    class AssetServer

      ILLEGAL_PATH_REGEX = /(\/\.\.?)/

      BLANK_PATH_MESSAGE = 'Please specify non-blank path when initializing rack-zippy middleware ' +
        '(path leads to your public directory, often the one with favicon.ico in it)'

      attr_reader :static_middleware

      def initialize(app, path=nil, options={})
        raise ArgumentError, BLANK_PATH_MESSAGE if path.blank?
        @static_middleware = ::ActionDispatch::Static.new(app, path)
      end

      def call(env)
        return not_found_response if illegal_path?(env)

        static_middleware.call(env)
      end

      private

      def illegal_path?(env)
        path_info = env['PATH_INFO']
        path_info =~ ILLEGAL_PATH_REGEX
      end

      def not_found_response
        [404, {}, ['Not Found']]
      end

    end
  end
end
