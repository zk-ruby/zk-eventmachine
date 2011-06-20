require 'eventmachine'

require 'zookeeper'
require 'zookeeper/em_client'

require 'zk'


module ZK
  module ZKEventMachine
    def self.new(host_str=nil)
      host_str ||= 'localhost:2181'
      Client.new(host_str)
    end
  end
end


$LOAD_PATH.unshift(File.expand_path('../..', __FILE__)).uniq!

require 'z_k/z_k_event_machine/iterator'
require 'z_k/z_k_event_machine/deferred'
require 'z_k/z_k_event_machine/callback'
require 'z_k/z_k_event_machine/event_handler_e_m'
require 'z_k/z_k_event_machine/unixisms'
require 'z_k/z_k_event_machine/client'


