require_relative 'test_helper'

class Rack::Zippy::AssetServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    ensure_correct_working_directory
  end

  def teardown
    revert_to_original_working_directory
  end

  def app
    response = 'Up above the streets and houses'
    headers = {}
    status = 200
    rack_app = lambda { |env| [status, headers, response] }
    Rack::Zippy::AssetServer.new(rack_app)
  end

  def test_responds_with_maximum_cache_headers_for_assets_subdir_requests
    get '/assets/favicon.ico'
    assert_cache_max_age :year
    assert_cache_friendly_last_modified
  end

  def test_responds_with_month_long_cache_headers_for_root_favicon
    get '/favicon.ico'
    assert_cache_max_age :month
    assert_cache_friendly_last_modified
  end

  def test_responds_with_day_long_cache_headers_for_robots_txt
    get '/robots.txt'
    assert_cache_max_age :day
    assert_cache_friendly_last_modified
  end

  def test_responds_with_day_long_cache_headers_for_root_html_requests
    get '/thanks.html'
    assert_cache_max_age :day
    assert_cache_friendly_last_modified
  end

  #def test_vary_accept_encoding_header_present_for_css_requests_by_non_gzip_clients
  #  flunk
  #end
  #
  #def test_vary_accept_encoding_header_present_for_js_requests_by_non_gzip_clients
  #  flunk
  #end

  def test_throws_exception_if_path_contains_consecutive_periods
    e = assert_raises SecurityError do
      get '/hello/../sensitive/file'
    end
    assert_equal 'Illegal path requested', e.message
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

  def test_passes_non_asset_requests_onto_app
    get '/about'
    assert_underlying_app_responded
  end

  def test_does_not_pass_not_found_asset_requests_onto_app
    get '/index.html'
    assert_not_found
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

  def test_responds_404_not_found_for_non_existent_image
    get '/assets/pot-of-gold.png'
    assert_not_found
  end

  def test_responds_404_not_found_for_non_existent_css
    get '/assets/unicorn.css'
    assert_not_found
  end

  def test_responds_404_not_found_for_non_existent_js
    get '/assets/dragon.js'
    assert_not_found
  end

  private

  DURATIONS_IN_SECS = {:year => 31536000, :month => 2678400, :day => 86400}.freeze

  def assert_cache_max_age(duration)
    assert_equal "public, max-age=#{DURATIONS_IN_SECS[duration]}", last_response.headers['cache-control']
  end

  # Browsers favour caching assets with older Last Modified dates IIRC
  def assert_cache_friendly_last_modified
    assert_equal 'Mon, 10 Jan 2005 10:00:00 GMT', last_response.headers['last-modified']
  end

  def assert_underlying_app_responded
    assert_response_ok
    assert 'Up above the streets and houses', last_response.body
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

  def assert_not_found
    assert_equal 404, last_response.status
    assert_equal 'Not Found', last_response.body
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