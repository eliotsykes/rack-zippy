require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'test/unit'
require 'rack/test'

module Rails

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

end