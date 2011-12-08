module ZK
  module ZKEventMachine
    module Locker
      # This class makes use of EM::Synchrony and the SynchronyClient, so the 
      # calling conventions are somewhat different than the rest of the library.
      #
      # These methods will appear to block the caller, but will actually use fibers
      # behind the scenes to relase control to EM when we are awaiting a reply.
      #
      # Another thing to note is that since this is synchronous-style,
      # *exceptions will be raised* and should be caught using a normal
      # begin/rescue/end block
      #
      #
      class LockerBase < ZK::Locker::LockerBase
        include ZK::Logging
        include FiberHelper

        # TODO, move ROOT_LOCK_NODE into ZK
        ROOT_LOCK_NODE = "/_zklocking"

        # @private
        def self.digit_from_lock_path(path) #:nodoc:
          path[/0*(\d+)$/, 1].to_i
        end

        # takes a ZK::ZKEventMachine::Client as first argument
        def initialize(zkem_client, name, root_lock_node=ROOT_LOCK_NODE)
          super(zkem_client.to_synchrony, name, root_lock_node)
        end

      end # LockerBase

      class SharedLocker < LockerBase
      end # SharedLocker
    end # Locker
  end # ZKEventMachine
end # ZK

