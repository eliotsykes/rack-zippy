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
      end

      def test_day_long_cache_headers_for_root_html_requests
        serveable_file = ServeableFile.new(
          :full_path_info => "/thanks.html",
          :path => "#{asset_root}/thanks.html",
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        cache_headers = serveable_file.cache_headers

        assert_cache_max_age cache_headers, :day
        assert_last_modified cache_headers, nil
      end

      def test_max_age_fallback_used_for_cache_headers
        
        ten_mins_in_secs = 10*60

        serveable_file = ServeableFile.new(
          :full_path_info => "/thanks.html",
          :path => "#{asset_root}/thanks.html",
          :has_encoding_variants => false,
          :is_gzipped => false,
          :max_age_fallback => ten_mins_in_secs
        )

        cache_headers = serveable_file.cache_headers

        assert_cache_max_age cache_headers, ten_mins_in_secs
        assert_last_modified cache_headers, nil
      end

      def test_cache_max_age_is_month_for_root_favicon
        serveable_file = ServeableFile.new(
          :full_path_info => "/favicon.ico",
          :path => "#{asset_root}/favicon.ico",
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        assert_cache_max_age serveable_file.cache_headers, :month
      end

      def test_maximum_cache_headers_for_assets_subdir_requests
        serveable_file = ServeableFile.new(
          :full_path_info => "/assets/favicon.ico",
          :path => "#{asset_root}/assets/favicon.ico",
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        cache_headers = serveable_file.cache_headers

        assert_cache_max_age cache_headers, :year
        assert_cache_friendly_last_modified cache_headers
      end

      def test_cache_friendly_last_modified_is_not_set_for_files_outside_of_assets_subdir
        serveable_file = ServeableFile.new(
          :full_path_info => "/robots.txt",
          :path => "#{asset_root}/robots.txt",
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        assert_last_modified serveable_file.cache_headers, nil
      end

      def test_cache_friendly_last_modified_is_set_for_root_favicon_as_it_rarely_changes
        serveable_file = ServeableFile.new(
          :full_path_info => "/favicon.ico",
          :path => "#{asset_root}/favicon.ico",
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        assert_cache_friendly_last_modified serveable_file.cache_headers
      end

      def test_headers_sets_content_length
        path = "#{asset_root}/thanks.html"

        serveable_file = ServeableFile.new(
          :full_path_info => "/thanks.html",
          :path => path,
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        headers = serveable_file.headers

        file_size_in_bytes = ::File.size(path)
        assert_equal 108, file_size_in_bytes
        assert_equal file_size_in_bytes, headers['Content-Length'].to_i
      end

      def test_headers_does_not_set_vary_header_for_file_without_gzipped_counterpart
        serveable_file = ServeableFile.new(
          :full_path_info => "/thanks.html",
          :path => "#{asset_root}/thanks.html",
          :has_encoding_variants => false,
          :is_gzipped => false
        )

        headers = serveable_file.headers

        assert_nil headers['Vary']
        assert_nil headers['Content-Encoding']
      end

      def test_headers_sets_encoding_related_headers_for_gzipped_asset
        serveable_file = ServeableFile.new(
          :full_path_info => "/assets/application.css",
          :path => "#{asset_root}/assets/application.css.gz",
          :has_encoding_variants => true,
          :is_gzipped => true
        )

        headers = serveable_file.headers

        assert_equal 'Accept-Encoding', headers['Vary']
        assert_equal 'gzip', headers['Content-Encoding']
      end

      def test_headers_sets_vary_header_for_uncompressed_asset_with_gzipped_counterpart
        serveable_file = ServeableFile.new(
          :full_path_info => "/assets/application.css",
          :path => "#{asset_root}/assets/application.css",
          :has_encoding_variants => true,
          :is_gzipped => false
        )

        headers = serveable_file.headers

        assert_equal 'Accept-Encoding', headers['Vary']
        assert_nil headers['Content-Encoding']        
      end

      def test_headers_sets_content_type_header_for_gzipped_asset
        serveable_file = ServeableFile.new(
          :full_path_info => "/assets/application.js",
          :path => "#{asset_root}/assets/application.js.gz",
          :has_encoding_variants => true,
          :is_gzipped => true
        )

        headers = serveable_file.headers

        assert_equal "application/javascript", headers['Content-Type']
      end

      def test_response_body_returns_file_contents_in_array_as_required_by_rack
        path = "#{asset_root}/thanks.html"

        serveable_file = ServeableFile.new(
          :path => path,
          :has_encoding_variants => false
        )

        assert_equal [::File.read(path)], serveable_file.response_body
      end

      def test_has_encoding_variants_must_be_given_as_constructor_option_to_ensure_vary_encoding_header_can_be_determined
        e = assert_raises ArgumentError do
          ServeableFile.new({})
        end
        assert_equal ':has_encoding_variants option must be given', e.message
      end

      def test_encoding_variants_returns_true_when_constructor_option_true
        serveable_file = ServeableFile.new(:has_encoding_variants => true)
        assert serveable_file.encoding_variants?
      end

      def test_encoding_variants_returns_false_when_constructor_option_false
        serveable_file = ServeableFile.new(:has_encoding_variants => false)
        assert !serveable_file.encoding_variants?
      end

      def test_gzipped_returns_false_when_constructor_option_false
        serveable_file = ServeableFile.new(:is_gzipped => false, :has_encoding_variants => true)
        assert !serveable_file.gzipped?
      end

      def test_gzipped_returns_true_when_constructor_option_true
        serveable_file = ServeableFile.new(:is_gzipped => true, :has_encoding_variants => true)
        assert serveable_file.gzipped?
      end

      def test_gzipped_defaults_to_false_when_no_constructor_option_given
        serveable_file = ServeableFile.new({:has_encoding_variants => true})
        assert !serveable_file.gzipped?
      end


      def test_serveable_files_with_same_options_are_equal
        file1 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        file2 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        assert_equal file1, file2
        assert_equal file2, file1
        assert file1.eql?(file2)
        assert file2.eql?(file1)
      end

      def test_serveable_files_with_different_paths_are_not_equal
        file1 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        file2 = ServeableFile.new :path => "#{asset_root}/foo/bar.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        assert_not_equal file1, file2
        assert_not_equal file2, file1
        assert !file1.eql?(file2)
        assert !file2.eql?(file1)
      end

      def test_serveable_files_with_different_path_info_are_not_equal
        file1 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        file2 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/foo/bar.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        assert_not_equal file1, file2
        assert_not_equal file2, file1
        assert !file1.eql?(file2)
        assert !file2.eql?(file1)
      end

      def test_serveable_files_with_different_has_encoding_variants_are_not_equal
        file1 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        file2 = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => false,
                                  :is_gzipped => true

        assert_not_equal file1, file2
        assert_not_equal file2, file1
        assert !file1.eql?(file2)
        assert !file2.eql?(file1)
      end

      def test_serveable_files_with_different_is_gzipped_are_not_equal
        file1 = ServeableFile.new :path => "#{asset_root}/hello/world.html",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => false

        file2 = ServeableFile.new :path => "#{asset_root}/hello/world.html",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        assert_not_equal file1, file2
        assert_not_equal file2, file1
        assert !file1.eql?(file2)
        assert !file2.eql?(file1)
      end

      def test_gzipped_serveable_file_does_not_equal_its_non_gzipped_counterpart
        gzipped = ServeableFile.new :path => "#{asset_root}/hello/world.html.gz",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => true

        not_gzipped = ServeableFile.new :path => "#{asset_root}/hello/world.html",
                                  :full_path_info => '/hello/world.html',
                                  :has_encoding_variants => true,
                                  :is_gzipped => false

        assert_not_equal gzipped, not_gzipped
        assert_not_equal not_gzipped, gzipped
        assert !gzipped.eql?(not_gzipped)
        assert !not_gzipped.eql?(gzipped)
      end

      def test_find_first_finds_static_file_as_directory
        paths = ['/foo/bar.html', '/foo/bar/', '/foo/bar']
        paths.each do |path|
          serveable_file = ServeableFile.find_first(
            :path_info => path,
            :asset_compiler => NullAssetCompiler.new,
            :asset_root => asset_root,
            :include_gzipped => false
          )

          assert serveable_file, "ServeableFile should be found for path info '#{path}'"
          assert_equal "#{asset_root}/foo/bar.html", serveable_file.path
          assert_equal "/foo/bar.html", serveable_file.full_path_info
        end
      end

      def test_find_first_finds_static_index_in_directory
        paths = ['/foo/index.html', '/foo/', '/foo']
        paths.each do |path|
          serveable_file = ServeableFile.find_first(
            :path_info => path,
            :asset_compiler => NullAssetCompiler.new,
            :asset_root => asset_root,
            :include_gzipped => false
          )

          assert serveable_file, "ServeableFile should be found for path info '#{path}'"
          assert_equal "#{asset_root}/foo/index.html", serveable_file.path
          assert_equal "/foo/index.html", serveable_file.full_path_info
        end
      end

      def test_find_first_finds_static_index_at_root
        valid_root_paths = [
          '/index.html', '/index', '/', ''
        ]
        valid_root_paths.each do |root|

          serveable_file = ServeableFile.find_first(
            :path_info => root,
            :asset_compiler => NullAssetCompiler.new,
            :asset_root => asset_root,
            :include_gzipped => false
          )

          assert serveable_file, "ServeableFile should be found for root path info '#{root}'"
          assert_equal "#{asset_root}/index.html", serveable_file.path
          assert_equal "/index.html", serveable_file.full_path_info
        end
      end

      def test_find_first_finds_nothing_for_non_static_extension
        assert_nil ServeableFile.find_first(
            :path_info => '/about',
            :asset_compiler => NullAssetCompiler.new,
            :asset_root => asset_root
        )
      end

      def test_find_first_finds_nothing_for_compileable_path_info
        ::Rails.configuration.assets.compile = true
        
        asset_compiler = RailsAssetCompiler.new
        
        path_info = '/assets/main.css'
        
        assert asset_compiler.compiles?(path_info), 
            "asset compiler should compile '#{path_info}'"
        
        assert_nil ServeableFile.find_first(
            :path_info => path_info,
            :asset_compiler => asset_compiler
        )
      end

      def test_find_first_finds_gzip_variant
        
        result = ServeableFile.find_first(
          :path_info => "/assets/application.css",
          :asset_compiler => NullAssetCompiler.new,
          :asset_root => asset_root,
          :include_gzipped => true
        )
        
        assert_equal "#{asset_root}/assets/application.css.gz", result.path,
            "gzipped file variant should be found"
        assert_equal "/assets/application.css", result.full_path_info
        assert result.encoding_variants?
        assert result.gzipped?
      end

      def test_find_first_finds_uncompressed_file_when_include_gzipped_false
        result = ServeableFile.find_first(
          :path_info => "/assets/application.css",
          :asset_compiler => NullAssetCompiler.new,
          :asset_root => asset_root,
          :include_gzipped => false
        )
        
        assert_equal "#{asset_root}/assets/application.css", result.path,
            "non-gzipped file variant should be found"
        assert_equal "/assets/application.css", result.full_path_info
        assert result.encoding_variants?
        assert !result.gzipped?
      end

      def test_find_first_finds_uncompressed_file_that_has_no_gzip_variant
        result = ServeableFile.find_first(
          :path_info => "/thanks.html",
          :asset_compiler => NullAssetCompiler.new,
          :asset_root => asset_root,
          :include_gzipped => true
        )

        assert_equal "#{asset_root}/thanks.html", result.path
        assert_equal "/thanks.html", result.full_path_info
        assert !result.encoding_variants?
        assert !result.gzipped?
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
