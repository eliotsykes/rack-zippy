module Rack
  module Zippy

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

  end
end