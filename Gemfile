source "https://rubygems.org"

if ENV['ACTIVEMODEL_VERSION']
  gem 'activemodel', ENV['ACTIVEMODEL_VERSION']
end
gemspec

gem 'jruby-openssl', :platform => :jruby
gem 'activesupport', '< 5' if RUBY_VERSION < '2.2.2'
gem 'rake', '< 12'
