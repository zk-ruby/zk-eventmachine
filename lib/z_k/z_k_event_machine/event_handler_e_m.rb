module ZK
  module ZKEventMachine
    # a small wrapper around the EventHandler instance, allowing us to 
    # deliver the event on the reactor thread, as opposed to calling it directly
    #
    class EventHandlerEM < ZK::EventHandler
      include ZK::Logging

      def register(path, &block)
        # use the supplied block, but ensure that it gets called on the reactor
        # thread
        new_blk = lambda do |*a|
          EM.schedule { block.call(*a) }
        end

        super(path, &new_blk)
      end
      alias :subscribe :register

      def process(event)
        EM.schedule { super(event) }
      end

      protected
        # we're running on the Reactor, don't need to synchronize (hah, hah, we'll see...)
        #
        def synchronize
          yield
        end
    end
  end
end


