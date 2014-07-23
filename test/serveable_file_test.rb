require_relative 'test_helper'

class Rack::Zippy::ServeableFileTest < Test::Unit::TestCase

  def setup
    ::Rails.configuration.assets.compile = false
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