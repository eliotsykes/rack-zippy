require_relative 'test_helper'
require 'rack-zippy/asset_compiler'

module Rack
  module Zippy
    class NullAssetCompilerTest < TestCase

      def test_never_wants_to_compile_assets
        asset_compiler = NullAssetCompiler.new
        assert !asset_compiler.compiles?('/assets/application.css')
      end

    end
  end
end
