#!/usr/bin/env ruby
# encoding: utf-8

require 'simplecov'
if ENV['COVERAGE']
	SimpleCov.start
end

require 'fileutils'
require 'pp'
require 'ydocx'

module YDcoxHelper
  DataDir = File.join(File.dirname(__FILE__), '..', 'spec', 'data')
end
require 'rspec'
require 'ydocx'