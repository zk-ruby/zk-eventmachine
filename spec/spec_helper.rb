require 'rubygems'
require 'bundler/setup'
require 'logger'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'zk-eventmachine'
require 'evented-spec'

ZK.logger = Logger.new(File.expand_path('../../test.log', __FILE__)).tap {|l| l.level = Logger::DEBUG}

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

$stderr.sync = true

RSpec.configure do |config|
  config.mock_with :flexmock
end

# method to wait until block passed returns true or timeout (default is 2 seconds) is reached 
def wait_until(timeout=2)
  time_to_stop = Time.now + timeout

  until yield 
    break if Time.now > time_to_stop
    Thread.pass
  end
end

def wait_while(timeout=2)
  time_to_stop = Time.now + timeout

  while yield 
    break if Time.now > time_to_stop
    Thread.pass
  end
end

class ::Thread
  # join with thread until given block is true, the thread joins successfully, 
  # or timeout seconds have passed
  #
  def join_until(timeout=2)
    time_to_stop = Time.now + timeout

    until yield
      break if Time.now > time_to_stop
      break if join(0.1)
    end
  end
  
  def join_while(timeout=2)
    time_to_stop = Time.now + timeout

    while yield
      break if Time.now > time_to_stop
      break if join(0.1)
    end
  end
end



