require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'minitest/autorun'
require 'rack/test'
require 'active_support/testing/declarative'


class TestCase < ::Minitest::Test
  extend ActiveSupport::Testing::Declarative

  DURATIONS_IN_SECS = {:year => 31536000, :month => 2678400, :day => 86400}.freeze

  def ensure_correct_working_directory
    is_project_root_working_directory = ::File.exists?('rack-zippy.gemspec')
    if is_project_root_working_directory
      @original_dir = Dir.pwd
      Dir.chdir 'test'
    end
  end

  def revert_to_original_working_directory
    Dir.chdir @original_dir if @original_dir
  end

  def asset_root
    "#{Dir.pwd}/public"
  end


end
