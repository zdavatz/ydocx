#!/usr/bin/env ruby
# encoding: utf-8

require 'fileutils'
require 'pp'
require 'ydocx'

RSpec.configure do |c|
  # Enable colour
  c.tty = true
end

proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
@@data_dir = File.join(proj_root, 'spec', 'data')
