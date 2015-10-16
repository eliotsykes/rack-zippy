require_relative 'test_helper'

module Rack
  module Zippy
    class ServeableFileTest < TestCase

      CACHE_FRIENDLY_LAST_MODIFIED = 'Mon, 10 Jan 2005 10:00:00 GMT'

      def setup
        ensure_correct_working_directory
        enter_rails_env
        ::Rails.configuration.assets.compile = false
      end

      def teardown
        revert_to_original_working_directory
        Rack::Zippy.reset_static_extensions
      end


      def test_find_first_finds_nothing_for_static_extension_and_non_existent_file
        assert_nil ServeableFile.find_first(
          :path_info => '/about.html',
          :asset_compiler => NullAssetCompiler.new,
          :asset_root => asset_root,
          :include_gzipped => false
        )
      end

      def test_has_static_extension_handles_non_lowercase_chars
        ['pNG', 'JPEG', 'HTML', 'HtM', 'GIF', 'Ico'].each do |extension|
          assert ServeableFile.has_static_extension?("/some-asset.#{extension}")
        end
      end

      def test_has_static_extension_returns_false_for_asset_paths_without_period
        ['/assets/somepng', '/indexhtml', '/assets/applicationcss'].each do |path|
          assert !ServeableFile.has_static_extension?(path)
        end
      end

      def test_has_static_extension_returns_true_for_fonts
        font_extensions = ['woff', 'woff2', 'ttf', 'eot', 'otf']
        font_extensions.each do |extension|
          assert ServeableFile.has_static_extension?("/comic-sans.#{extension}"),
                 "'#{extension}' font extension not recognized"
        end
      end

      def test_has_static_extension_returns_true_for_flash
        assert ServeableFile.has_static_extension?('/splash-page-like-its-1999.swf'),
               "Should handle flash .swf files"
      end

      def test_has_static_extension_returns_true_for_configured_extension
        Rack::Zippy.static_extensions << 'csv'
        assert ServeableFile.has_static_extension?('/static-file.csv'),
               "Should handle files with user configured extensions"
      end

      private

      def assert_last_modified(headers, expected)
        assert_equal expected, headers['Last-Modified']
      end

      def assert_cache_friendly_last_modified(headers)
        assert_last_modified headers, CACHE_FRIENDLY_LAST_MODIFIED
      end

      def assert_cache_max_age(headers, expected_duration)
        duration_in_secs = DURATIONS_IN_SECS[expected_duration] || expected_duration
        assert_equal "public, max-age=#{duration_in_secs}", headers['Cache-Control']
      end

    end
  end
end
