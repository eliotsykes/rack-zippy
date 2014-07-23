require_relative 'test_helper'

class Rack::Zippy::ServeableFileTest < Test::Unit::TestCase

  def setup
    ::Rails.configuration.assets.compile = false
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