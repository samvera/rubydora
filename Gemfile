source "https://rubygems.org"

if ENV['ACTIVEMODEL_VERSION']
  gem 'activemodel', ENV['ACTIVEMODEL_VERSION']
end
gemspec

gem 'jruby-openssl', :platform => :jruby

# We can remove this when we upgrade rspec.
# See https://github.com/ruby/rake/issues/116
gem 'rake', '< 12'

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
    ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
