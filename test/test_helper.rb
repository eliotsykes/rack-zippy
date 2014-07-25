require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'test/unit'
require 'rack/test'

module RailsEnvironmentStub

  @@public_path = '/default/path/to/public/set/in/test_helper'

  @@configuration = Struct.new(:assets).new
  @@configuration.assets = Struct.new(:compile).new

  def self.configuration
    @@configuration
  end

  def self.public_path
    @@public_path
  end

  def self.public_path=(path)
    @@public_path = path
  end

  def self.version
    return 'Rails.version stub'
  end

end

class TestCase < ::Test::Unit::TestCase

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

  def enter_rails_env
    Object.send(:const_set, :Rails, ::RailsEnvironmentStub) unless defined?(::Rails)
  end

  def exit_rails_env
    Object.send(:remove_const, :Rails)
  end

  def in_rails_env?
    return defined?(::Rails)
  end

end
