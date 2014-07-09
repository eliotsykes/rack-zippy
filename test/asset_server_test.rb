require_relative 'test_helper'

class Rack::Zippy::AssetServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    ensure_correct_working_directory
    ::Rails.public_path = Pathname.new("#{Dir.pwd}/public")
    ::Rails.configuration.assets.compile = false
  end

  def teardown
    revert_to_original_working_directory
  end

  def app
    Rack::Zippy::AssetServer.new(create_rack_app)
  end

  def test_request_for_non_asset_path_beginning_with_assets_dir_name_bypasses_middleware
    get '/assets-are-great-but-im-not-one'
    assert_underlying_app_responded
  end

  def test_request_for_subdir_of_assets_passed_onto_app
    ['/assets/blog', '/assets/blog/logos/'].each do |path|
      local_path = "public#{path}"
      assert File.directory?(local_path)
      get path
      assert_underlying_app_responded
    end
  end

  def test_request_for_non_existent_subdir_of_assets_passed_onto_app
    ['/assets/ghost', '/assets/does/not/exist', '/assets/nothing-here/with-trailing-slash/'].each do |path|
      local_path = "public#{path}"
      assert !File.exists?(local_path)
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

  def test_does_not_serve_assets_subdir_request_when_assets_compile_enabled
    ::Rails.configuration.assets.compile = true
    get '/assets/application.css'
    assert_underlying_app_responded
  end

  def test_serve_returns_true_if_request_has_static_extension_and_file_exists
    assert app.send(:serve?, '/thanks.html')
  end

  def test_serve_returns_false_if_request_has_static_extension_and_file_does_not_exist
    assert !app.send(:serve?, '/about.html')
  end

  def test_serve_returns_false_if_request_does_not_have_static_extension
    assert !app.send(:serve?, '/about')
  end

  def test_serve_returns_true_for_assets_subdir_request_when_assets_compile_disabled
    assert app.send(:serve?, '/assets/application.css')
  end

  def test_serve_returns_false_for_assets_subdir_request_when_assets_compile_enabled
    ::Rails.configuration.assets.compile = true
    assert !app.send(:serve?, '/assets/application.css')
  end

  def test_block_asset_pipeline_from_generating_asset_returns_false_if_assets_compile_enabled
    ::Rails.configuration.assets.compile = true
    assert ::Rails.configuration.assets.compile
    assert !app.send(:block_asset_pipeline_from_generating_asset?)
  end

  def test_block_asset_pipeline_from_generating_asset_returns_true_if_assets_compile_disabled
    assert !::Rails.configuration.assets.compile
    assert app.send(:block_asset_pipeline_from_generating_asset?)
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
  end

  def assert_raises_illegal_path_error(path)
    e = assert_raises SecurityError do
      get path
    end
    assert_equal 'Illegal path requested', e.message
  end

  def test_throws_exception_if_path_contains_hidden_dir
    paths = ['.confidential/secret-plans.pdf', '/.you-aint-seen-me/index.html', '/nothing/.to/see/here.jpg']
    paths.each do |path|
      assert_raises_illegal_path_error path
    end
  end

  def test_throws_exception_if_path_ends_with_hidden_file
    hidden_files = ['.htaccess', '/.top-secret', '/assets/.shhh']
    hidden_files.each do |path|
      assert_raises_illegal_path_error path
    end
  end

  def test_throws_exception_if_path_contains_consecutive_periods
    assert_raises_illegal_path_error '/hello/../sensitive/file'
  end

  def test_serves_html
    get '/thanks.html'
    assert_response_ok
    assert_content_type 'text/html'
    assert_content_length 'public/thanks.html'
  end

  def test_serves_robots_txt
    get '/robots.txt'
    assert_response_ok
    assert_content_type 'text/plain'
    assert_content_length 'public/robots.txt'
  end

  def test_has_static_extension_handles_non_lowercase_chars
    ['pNG', 'JPEG', 'HTML', 'HtM', 'GIF', 'Ico'].each do |extension|
      assert app.send(:has_static_extension?, "/some-asset.#{extension}")
    end
  end

  def test_has_static_extension_returns_false_for_asset_paths_without_period
    ['/assets/somepng', '/indexhtml', '/assets/applicationcss'].each do |path|
      assert !app.send(:has_static_extension?, path)
    end
  end

  def test_has_static_extension_returns_true_for_fonts
    font_extensions = ['woff', 'woff2', 'ttf', 'eot', 'otf']
    font_extensions.each do |extension|
      assert app.send(:has_static_extension?, "/comic-sans.#{extension}"),
             "'#{extension}' font extension not recognized"
    end
  end

  def test_has_static_extension_returns_true_for_flash
    assert app.send(:has_static_extension?, '/splash-page-like-its-1999.swf'),
           "Should handle flash .swf files"
  end

  def test_passes_non_asset_requests_onto_app
    get '/about'
    assert_underlying_app_responded
  end

  def test_passes_not_found_asset_requests_onto_app
    get '/index.html'
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

  def test_asset_root_constructor_arg_accepts_string
    asset_server = Rack::Zippy::AssetServer.new(create_rack_app, '/custom/asset/root')
    assert_equal '/custom/asset/root', asset_server.instance_variable_get('@asset_root')
  end

  def test_default_asset_root_is_rails_public_path
    Rails.public_path = '/unexpected/absolute/path/to/public'
    asset_server = Rack::Zippy::AssetServer.new(create_rack_app)
    assert_equal '/unexpected/absolute/path/to/public', asset_server.instance_variable_get('@asset_root')
  end

  private

  DURATIONS_IN_SECS = {:year => 31536000, :month => 2678400, :day => 86400}.freeze

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

  def assert_response_ok
    assert_equal 200, last_response.status
  end

  def assert_content_type(expected_content_type)
    assert_equal expected_content_type, last_response.headers['content-type']
  end

  def assert_content_length(path)
    assert_equal ::File.size(path).to_s, last_response.headers['content-length']
  end

  def assert_not_found(msg=nil)
    assert_equal 404, last_response.status, msg
    assert_equal 'Not Found', last_response.body, msg
  end

  def ensure_correct_working_directory
    is_project_root_working_directory = File.exists?('rack-zippy.gemspec')
    if is_project_root_working_directory
      @original_dir = Dir.pwd
      Dir.chdir 'test'
    end
  end

  def revert_to_original_working_directory
    Dir.chdir @original_dir if @original_dir
  end

end