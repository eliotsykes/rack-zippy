require_relative 'test_helper'

module Rack
  module Zippy
    class ServeableFileTest < TestCase

      def setup
        ensure_correct_working_directory
        ::Rails.configuration.assets.compile = false
      end

      def teardown
        revert_to_original_working_directory
      end

      def test_servable_files_with_same_path_are_equal
        file1 = ServeableFile.new '/hello/world.html'
        file2 = ServeableFile.new '/hello/world.html'
        assert_equal file1, file2
        assert_equal file2, file1
        assert file1.eql?(file2)
        assert file2.eql?(file1)
      end

      def test_serveable_files_with_different_paths_are_not_equal
        file1 = ServeableFile.new '/hello/world.html'
        file2 = ServeableFile.new '/foo/bar.html'
        assert_not_equal file1, file2
        assert_not_equal file2, file1
        assert !file1.eql?(file2)
        assert !file2.eql?(file1)
      end

      def test_find_all_finds_serveable_file_with_static_extension
        path = "#{asset_root}/thanks.html"
        files = ServeableFile.find_all(:path_info => '/thanks.html', :path => path)
        assert_equal [ServeableFile.new(path)], files
      end

      def test_find_all_finds_nothing_for_static_extension_and_non_existent_file
        assert_empty ServeableFile.find_all(:path_info => '/about.html', :path => "#{asset_root}/about.html")
      end

      def test_find_all_finds_nothing_for_non_static_extension
        assert_empty ServeableFile.find_all(:path_info => '/about', :path => "#{asset_root}/about")
      end

      def test_find_all_finds_serveable_file_for_assets_subdir_path_info_when_assets_compile_disabled
        path = "#{asset_root}/assets/application.css"
        files = ServeableFile.find_all(:path_info => '/assets/application.css', :path => path)
        assert_equal [ServeableFile.new(path)], files
      end

      def test_find_all_finds_nothing_for_assets_subdir_request_when_assets_compile_enabled
        ::Rails.configuration.assets.compile = true
        assert_empty ServeableFile.find_all(:path_info => '/assets/application.css', :path => "#{asset_root}/assets/application.css")
      end

      def test_has_static_extension_handles_non_lowercase_chars
        ['pNG', 'JPEG', 'HTML', 'HtM', 'GIF', 'Ico'].each do |extension|
          assert Rack::Zippy::ServeableFile.has_static_extension?("/some-asset.#{extension}")
        end
      end

      def test_has_static_extension_returns_false_for_asset_paths_without_period
        ['/assets/somepng', '/indexhtml', '/assets/applicationcss'].each do |path|
          assert !Rack::Zippy::ServeableFile.has_static_extension?(path)
        end
      end

      def test_has_static_extension_returns_true_for_fonts
        font_extensions = ['woff', 'woff2', 'ttf', 'eot', 'otf']
        font_extensions.each do |extension|
          assert Rack::Zippy::ServeableFile.has_static_extension?("/comic-sans.#{extension}"),
                 "'#{extension}' font extension not recognized"
        end
      end

      def test_has_static_extension_returns_true_for_flash
        assert Rack::Zippy::ServeableFile.has_static_extension?('/splash-page-like-its-1999.swf'),
               "Should handle flash .swf files"
      end

      def test_block_asset_pipeline_from_generating_asset_returns_false_if_assets_compile_enabled
        ::Rails.configuration.assets.compile = true
        assert ::Rails.configuration.assets.compile
        assert !Rack::Zippy::ServeableFile.block_asset_pipeline_from_generating_asset?
      end

      def test_block_asset_pipeline_from_generating_asset_returns_true_if_assets_compile_disabled
        assert !::Rails.configuration.assets.compile
        assert Rack::Zippy::ServeableFile.block_asset_pipeline_from_generating_asset?
      end


    end
  end
end