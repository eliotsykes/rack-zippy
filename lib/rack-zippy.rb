require 'rack-zippy/version'
require 'action_controller'

module Rack
  module Zippy
    class AssetServer

      attr_reader :static_middleware

      # @param app [#call(env)] the Rack app
      # @param path [String] the path to the public directory, usually where favicon.ico lives
      # @param max_age_fallback [Fixnum] time for Cache-Control header. Defaults to 1 day (in seconds).
      def initialize(app, path, max_age_fallback: :day)
        assert_path_valid path

        cache_control = cache_control(max_age_fallback)

        @app = app
        blank_app = ->(env) { }
        @static_middleware = ::ActionDispatch::Static.new(blank_app, path, cache_control)
      end

      def call(env)
        return not_found_response if illegal_path?(env)

        static_response = static_middleware.call(env)

        if static_response
          # static middleware handled request
          static_response
        else
          @app.call(env)
        end
      end

      private

      ILLEGAL_PATH_REGEX = /(\/\.\.?)/

      BLANK_PATH_MESSAGE = 'Please specify non-blank path when initializing rack-zippy middleware ' +
        '(path leads to your public directory, often the one with favicon.ico in it)'

      SECONDS_IN = {
        day: 24*60*60,
        month: 31*(24*60*60),
        year: 365*(24*60*60)
      }.freeze

      def assert_path_valid(path)
        raise ArgumentError, BLANK_PATH_MESSAGE if path.blank?
      end

      def cache_control(max_age_fallback)
        max_age_fallback = calc_max_age_fallback(max_age_fallback)
        "public, max-age=#{max_age_fallback}"
      end

      def calc_max_age_fallback(max_age_fallback)
        max_age_fallback.is_a?(Symbol) ? SECONDS_IN.fetch(max_age_fallback) : max_age_fallback
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
