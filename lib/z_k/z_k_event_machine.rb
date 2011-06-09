require 'zk'
require 'eventmachine'
require 'zookeeper' # wtf?
require 'zookeeper/em_client'

module ZK
  module ZKEventMachine
  end
end


$LOAD_PATH.unshift(File.expand_path('../..', __FILE__)).uniq!

require 'z_k/z_k_event_machine/deferred'
require 'z_k/z_k_event_machine/callback'
require 'z_k/z_k_event_machine/event_handler_proxy'
require 'z_k/z_k_event_machine/client'


