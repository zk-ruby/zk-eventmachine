
%w[lib ext].each do |dir|
  $LOAD_PATH.unshift(File.expand_path("~/vendor/eventmachine/#{dir}")).uniq!
end
require 'eventmachine'

$stderr.puts "$eventmachine_library: #{$eventmachine_library.inspect}"

$LOAD_PATH.unshift(File.expand_path('~/zookeeper/lib')).uniq!

require 'zookeeper'
require 'zookeeper/em_client'

$LOAD_PATH.unshift(File.expand_path('~/zk/lib')).uniq!
require 'zk'


module ZK
  module ZKEventMachine
  end
end


$LOAD_PATH.unshift(File.expand_path('../..', __FILE__)).uniq!

require 'z_k/z_k_event_machine/iterator'
require 'z_k/z_k_event_machine/deferred'
require 'z_k/z_k_event_machine/callback'
require 'z_k/z_k_event_machine/event_handler_e_m'
require 'z_k/z_k_event_machine/unixisms'
require 'z_k/z_k_event_machine/client'


