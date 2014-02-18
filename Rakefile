# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'simplecov'

# Hoe.plugin :compiler
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :minitest
# Hoe.plugin :racc
# Hoe.plugin :rubyforge

Hoe.spec 'ydocx' do

  developer('Yasuhiro Asaka, Zeno R.R. Davatz', 'yasaka@ywesee.com,  zdavatz@ywesee.com')

end

namespace :spec do
desc "Create rspec coverage"
task :coverage do
ENV['COVERAGE'] = 'true'
Rake::Task["spec"].execute
end
end