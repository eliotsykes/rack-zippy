require 'rack-zippy/version'
require 'action_controller'

module Rack
  module Zippy
    class AssetServer

      attr_reader :static_middleware

      # @param app [#call] the Rack app
      # @param path [String] the path to the public directory, usually where favicon.ico lives
      # @param max_age_fallback [Fixnum] optional time in seconds that Cache-Control header should use instead of the default
      def initialize(app, path, max_age_fallback: :day)
        assert_path_valid path
        max_age_fallback = calc_max_age_fallback(max_age_fallback)

        cache_control = "public, max-age=#{max_age_fallback}"

        @static_middleware = ::ActionDispatch::Static.new(app, path, cache_control)
      end

      def call(env)
        return not_found_response if illegal_path?(env)

        static_middleware.call(env)
      end

      private

      ILLEGAL_PATH_REGEX = /(\/\.\.?)/

      BLANK_PATH_MESSAGE = 'Please specify non-blank path when initializing rack-zippy middleware ' +
        '(path leads to your public directory, often the one with favicon.ico in it)'

      SECONDS_IN = {
        :day => 24*60*60,
        :month => 31*(24*60*60),
        :year => 365*(24*60*60)
      }.freeze

      def calc_max_age_fallback(max_age_fallback)
        max_age_fallback.is_a?(Symbol) ? SECONDS_IN.fetch(max_age_fallback) : max_age_fallback
      end

      def assert_path_valid(path)
        raise ArgumentError, BLANK_PATH_MESSAGE if path.blank?
      end

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
