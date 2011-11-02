require 'eventmachine'
require 'em-synchrony'

require 'zookeeper'
require 'zookeeper/em_client'

require 'zk'


module ZK
  module ZKEventMachine
  end
end


$LOAD_PATH.unshift(File.expand_path('../..', __FILE__)).uniq!

require 'z_k/z_k_event_machine/deferred'
require 'z_k/z_k_event_machine/callback'
require 'z_k/z_k_event_machine/event_handler_e_m'
require 'z_k/z_k_event_machine/unixisms'
require 'z_k/z_k_event_machine/client'
require 'z_k/z_k_event_machine/synchrony_client'


