require 'rack-zippy/version'
require 'action_controller'

module Rack
  module Zippy
    class AssetServer

      BLANK_PATH_MESSAGE = 'Please specify non-blank path when initializing rack-zippy middleware ' +
        '(path leads to your public directory, often the one with favicon.ico in it)'

      def initialize(app, path=nil, options={})
        raise ArgumentError, BLANK_PATH_MESSAGE if path.blank?
        @static_middleware = ::ActionDispatch::Static.new(app, path)
      end

      def call(env)
        @static_middleware.call(env)
      end

    end
  end
end
