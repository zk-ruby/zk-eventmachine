require 'zk'
require 'eventmachine'
require 'zookeeper' # wtf?

module ZK
  module ZKEventMachine
  end
end

base = File.expand_path('../z_k_event_machine', __FILE__)

require "#{base}/callback"
require "#{base}/client"


