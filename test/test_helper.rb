require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'test/unit'
require 'rack/test'

module Rails

  @configuration = Struct.new(:assets).new
  @configuration.assets = Struct.new(:compile).new

  def self.configuration
    @configuration
  end

end