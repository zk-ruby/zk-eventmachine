module ZK
  module ZKEventMachine
    # a small wrapper around the EventHandler instance, allowing us to 
    # deliver the event on the reactor thread, as opposed to calling it directly
    #
    class EventHandlerProxy
      include ZK::Logging

      def initialize(event_handler)
        @event_handler = event_handler
      end

      def register(path, &block)
        @event_handler.register(path) do |*a|
          EM.next_tick { block.call(*a) }
        end
      end
      alias :subscribe :register

      def method_missing(sym, *a, &b)
        if @event_handler.respond_to?(sym)
          @event_handler.__send__(sym, *a, &b)
        else
          super
        end
      end
    end
  end
end


