# -*- ruby -*-

require 'rubygems'
require 'simplecov'
require 'rspec'
require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
end
