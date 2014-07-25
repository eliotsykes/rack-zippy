require_relative 'test_helper'

module Rack
  module Zippy
    class RailsAssetCompilerTest < TestCase

      def setup
        enter_rails_env
        ::Rails.configuration.assets.compile = false
      end

      def test_rails_env_detected_if_rails_version_defined
        assert ::Rails.version
        assert RailsAssetCompiler.rails_env?
      end

      def test_not_rails_env
        exit_rails_env
        assert !RailsAssetCompiler.rails_env?
      end

      def test_wants_to_compile_assets_when_active
        ::Rails.configuration.assets.compile = true
        asset_compiler = RailsAssetCompiler.new
        assert asset_compiler.send(:active?), 'should be active'
        assert asset_compiler.compiles?('/assets/application.css')
      end

      def test_does_not_want_to_compile_anything_when_inactive
        assert !::Rails.configuration.assets.compile, 'assets.compile should not be active'
        asset_compiler = RailsAssetCompiler.new
        assert !asset_compiler.send(:active?), 'should not be active'
        assert !asset_compiler.compiles?('/assets/application.css')
        assert !asset_compiler.compiles?('/thanks.html')
      end

      def test_does_not_want_to_compile_non_asset_when_active
        ::Rails.configuration.assets.compile = true
        asset_compiler = RailsAssetCompiler.new
        assert asset_compiler.send(:active?), 'should be active'
        assert !asset_compiler.compiles?('/thanks.html')
      end

    end
  end
end
