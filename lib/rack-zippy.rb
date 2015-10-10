require 'rack-zippy/version'
require 'action_controller'

module Rack
  module Zippy
    class AssetServer

      def initialize(app, asset_root=nil, options={})
        @static_middleware = ::ActionDispatch::Static.new(app, asset_root)
      end

      def call(env)
        @static_middleware.call(env)
      end

    end
  end
end
