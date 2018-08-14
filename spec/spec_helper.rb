$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter

SimpleCov.start

require 'rspec/autorun'
require 'rubydora'
require 'webmock/rspec'

WebMock.allow_net_connect!

RSpec.configure do |config|
end
