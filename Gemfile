source "https://rubygems.org"
# requires ruby 1.9 or later
gem 'rubyzip', '>1.0.0'
gem 'nokogiri', '>=1.6.0'
gem 'htmlentities'
gem 'rmagick'

group :development do
	gem 'rspec'#, '<2.9.0'
  gem 'rake'
	gem 'simplecov'
end

# The group debugger must be disabled for using a matrix build via github/actions
group :debugger do
	gem 'pry-debugger'
end if false
