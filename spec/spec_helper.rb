#!/usr/bin/env ruby
# encoding: utf-8

require 'simplecov'
if ENV['COVERAGE']
	SimpleCov.start
end

require 'fileutils'
require 'pp'
require 'ydocx'

proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
@@data_dir = File.join(proj_root, 'spec', 'data')
require 'rspec'
require 'ydocx'