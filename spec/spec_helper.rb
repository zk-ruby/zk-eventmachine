require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'zk-eventmachine'
require 'evented-spec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

$stderr.sync = true

RSpec.configure do |config|
  config.mock_with :flexmock
end


