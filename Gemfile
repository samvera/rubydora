source "https://rubygems.org"

if ENV['ACTIVEMODEL_VERSION']
  gem 'activemodel', ENV['ACTIVEMODEL_VERSION']
end
gemspec

gem 'jruby-openssl', :platform => :jruby

# We can remove this when we upgrade rspec.
# See https://github.com/ruby/rake/issues/116
gem 'rake', '< 12'
