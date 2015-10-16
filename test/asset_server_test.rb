require_relative 'test_helper'

module Rack
  module Zippy
    class AssetServerTest < TestCase
      include Rack::Test::Methods

      def setup
        ensure_correct_working_directory
        enter_rails_env
        ::Rails.public_path = Pathname.new(asset_root)
        # ::Rails.configuration.assets.compile = false
      end

      def teardown
        revert_to_original_working_directory
        @app = nil
      end

      BLANK_PATHS = [nil, '', '   ']

      BLANK_PATHS.each do |blank_path|
        test "initializer prevents blank path: #{blank_path.inspect}" do
          assert_raise ArgumentError do
            AssetServer.new(create_rack_app, blank_path)
          end
        end
      end

      def test_serves_static_file_as_directory
        expected_html_file = 'public/foo/bar.html'
        assert_responds_with_html_file '/foo/bar.html', expected_html_file
        assert_responds_with_html_file '/foo/bar/', expected_html_file
        assert_responds_with_html_file '/foo/bar', expected_html_file
      end

      def test_serves_static_index_in_directory
        directory_index_html = 'public/foo/index.html'
        assert_responds_with_html_file '/foo/index.html', directory_index_html
        assert_responds_with_html_file '/foo/', directory_index_html
        assert_responds_with_html_file '/foo', directory_index_html
      end

      def test_serves_static_index_at_root
        index_html_file = 'public/index.html'
        assert_responds_with_html_file '/index.html', 'public/index.html'
        assert_responds_with_html_file '/index', 'public/index.html'
        assert_responds_with_html_file '/', 'public/index.html'
        assert_responds_with_html_file '', 'public/index.html'
      end

      def test_request_for_non_asset_path_beginning_with_assets_dir_name_bypasses_middleware
        get '/assets-are-great-but-im-not-one'
        assert_underlying_app_responded
      end

      def test_request_for_subdir_of_assets_passed_onto_app
        ['/assets/blog', '/assets/blog/logos/'].each do |path|
          local_path = "public#{path}"
          assert ::File.directory?(local_path)
          get path
          assert_underlying_app_responded
        end
      end

      def test_request_for_non_existent_subdir_of_assets_passed_onto_app
        ['/assets/ghost', '/assets/does/not/exist', '/assets/nothing-here/with-trailing-slash/'].each do |path|
          local_path = "public#{path}"
          assert !::File.exists?(local_path)
          get path
          assert_underlying_app_responded
        end
      end

      def test_request_for_assets_root_passed_onto_app
        ['/assets/', '/assets'].each do |assets_root|
          get assets_root
          assert_underlying_app_responded
        end
      end

      def test_cache_friendly_last_modified_is_not_set_for_files_outside_of_assets_subdir
        get '/robots.txt'
        assert_response_ok
        assert_last_modified nil
      end

      def test_cache_friendly_last_modified_is_set_for_root_favicon_as_it_rarely_changes
        get '/favicon.ico'
        assert_response_ok
        assert_cache_friendly_last_modified
      end

      def test_responds_with_gzipped_css_to_gzip_capable_clients
        params = {}
        get '/assets/application.css', params, env_for_gzip_capable_client
        assert_response_ok
        assert_content_length 'public/assets/application.css.gz'
        assert_content_type 'text/css'
        assert_cache_max_age :year
        assert_cache_friendly_last_modified
        assert_equal 'gzip', last_response.headers['content-encoding']
        assert_vary_accept_encoding_header
      end

      def test_responds_with_gzipped_js_to_gzip_capable_clients
        params = {}
        get '/assets/application.js', params, env_for_gzip_capable_client
        assert_response_ok
        assert_content_length 'public/assets/application.js.gz'
        assert_content_type 'application/javascript'
        assert_cache_max_age :year
        assert_cache_friendly_last_modified
        assert_equal 'gzip', last_response.headers['content-encoding']
        assert_vary_accept_encoding_header
      end

      def test_responds_with_maximum_cache_headers_for_assets_subdir_requests
        get '/assets/favicon.ico'
        assert_response_ok
        assert_cache_max_age :year
        assert_cache_friendly_last_modified
      end

      def test_responds_with_month_long_cache_headers_for_root_favicon
        get '/favicon.ico'
        assert_response_ok
        assert_cache_max_age :month
      end

      def test_responds_with_day_long_cache_headers_for_robots_txt
        get '/robots.txt'
        assert_response_ok
        assert_cache_max_age :day
        assert_last_modified nil
      end

      def test_responds_with_day_long_cache_headers_for_root_html_requests
        get '/thanks.html'
        assert_response_ok
        assert_cache_max_age :day
        assert_last_modified nil
      end

      def test_max_cache_and_vary_accept_encoding_headers_present_for_css_requests_by_non_gzip_clients
        get '/assets/application.css'
        assert_response_ok
        assert_content_length 'public/assets/application.css'
        assert_content_type 'text/css'
        assert_cache_max_age :year
        assert_cache_friendly_last_modified
        assert_nil last_response.headers['content-encoding']
        assert_vary_accept_encoding_header
      end

      def test_max_cache_and_vary_accept_encoding_headers_present_for_js_requests_by_non_gzip_clients
        get '/assets/application.js'
        assert_response_ok
        assert_content_type 'application/javascript'
        assert_content_length 'public/assets/application.js'
        assert_cache_max_age :year
        assert_cache_friendly_last_modified
        assert_nil last_response.headers['content-encoding']
        assert_vary_accept_encoding_header
      end

      def test_vary_header_not_present_if_gzipped_asset_unavailable
        get '/assets/rails.png'
        assert_response_ok
        assert_nil last_response.headers['vary']
        assert_nil last_response.headers['content-encoding']
      end

      def test_responds_not_found_if_path_contains_hidden_dir
        paths = ['.confidential/secret-plans.pdf', '/.you-aint-seen-me/index.html', '/nothing/.to/see/here.jpg']
        paths.each do |path|
          get path
          assert_not_found
        end
      end

      def test_responds_not_found_if_path_ends_with_hidden_file
        hidden_files = ['.htaccess', '/.top-secret', '/assets/.shhh']
        hidden_files.each do |path|
          get path
          assert_not_found
        end
      end

      def test_responds_not_found_if_path_contains_consecutive_periods
        ["/hello/../sensitive/file", "/..", "/...", "../sensitive"].each do |dotty_path|
          get dotty_path
          assert_not_found
        end
      end

      def test_responds_ok_if_path_contains_periods_that_not_follow_slash
         ["/hello/path..with....periods/file", "/hello/path/with.a.period"].each do |dotty_path|
          get dotty_path
          assert_underlying_app_responded
        end
      end

      def test_serves_html
        assert_responds_with_html_file '/thanks.html', 'public/thanks.html'
      end

      def test_serves_robots_txt
        get '/robots.txt'
        assert_response_ok
        assert_content_type 'text/plain'
        assert_content_length 'public/robots.txt'
      end

      def test_passes_non_asset_requests_onto_app
        get '/about'
        assert_underlying_app_responded
      end

      def test_passes_not_found_asset_requests_onto_app
        get '/foo.html'
        assert_underlying_app_responded
      end

      def test_responds_with_favicon_in_assets_dir
        get '/assets/favicon.ico'
        assert_response_ok
        assert_content_type 'image/vnd.microsoft.icon'
        assert_content_length 'public/assets/favicon.ico'
      end

      def test_responds_with_favicon_at_root
        get '/favicon.ico'
        assert_response_ok
        assert_content_type 'image/vnd.microsoft.icon'
        assert_content_length 'public/favicon.ico'
      end

      def test_request_for_non_existent_image_passed_onto_app
        get '/assets/pot-of-gold.png'
        assert_underlying_app_responded
      end

      def test_request_for_non_existent_css_passed_onto_app
        get '/assets/unicorn.css'
        assert_underlying_app_responded
      end

      def test_request_for_non_existent_js_passed_onto_app
        get '/assets/dragon.js'
        assert_underlying_app_responded
      end

      def test_uses_max_age_fallback_in_cache_control
        fallback_in_secs = 1234
        @app = AssetServer.new(
          create_rack_app, asset_root, max_age_fallback: fallback_in_secs
        )

        get '/thanks.html'
        assert_equal "public, max-age=1234", last_response.headers['cache-control']
        assert_last_modified nil
      end

      private

      def app
        @app ||= AssetServer.new(create_rack_app, asset_root)
      end

      def create_rack_app
        status = 200
        headers = {}
        response = 'Up above the streets and houses'
        lambda { |env| [status, headers, response] }
      end

      def assert_last_modified(expected)
        assert_equal expected, last_response.headers['last-modified']
      end

      def env_for_gzip_capable_client
        {'HTTP_ACCEPT_ENCODING' => 'deflate,gzip,sdch'}
      end

      def assert_vary_accept_encoding_header
        assert_equal 'Accept-Encoding', last_response.headers['vary']
      end

      def assert_cache_max_age(duration)
        assert_equal "public, max-age=#{DURATIONS_IN_SECS[duration]}", last_response.headers['cache-control']
      end

      # Browser caching heuristics favour assets with older Last Modified dates IIRC
      def assert_cache_friendly_last_modified
        assert_last_modified 'Mon, 10 Jan 2005 10:00:00 GMT'
      end

      def assert_underlying_app_responded
        assert_response_ok
        assert_equal 'Up above the streets and houses', last_response.body
      end

      def assert_responds_with_html_file(path_info, expected_html_file)
        get path_info
        assert_response_ok
        assert_content_type 'text/html', "Wrong content type for GET '#{path_info}'"
        assert_content_length expected_html_file
        assert_equal ::IO.read(expected_html_file), last_response.body
      end

      def assert_response_ok
        assert_equal 200, last_response.status
      end

      def assert_content_type(expected_content_type, message=nil)
        assert_equal expected_content_type, last_response.headers['content-type'], message
      end

      def assert_content_length(path)
        assert_equal ::File.size(path).to_s, last_response.headers['content-length'], "Unexpected Content-Length header"
      end

      def assert_not_found(msg=nil)
        assert_equal 404, last_response.status, msg
        assert_equal 'Not Found', last_response.body, msg
      end

    end
  end
end
