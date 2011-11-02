module ZK
  module ZKEventMachine
    class SynchronyEventHandlerWrapper
      include ZK::Logging

      def initialize(event_handler)
        @event_handler = event_handler
      end

      # registers a block to be called back within a fiber context
      def register(path, &block)
        new_block = proc do |*a|
          Fiber.new { block.call(*a) }.resume
        end

        @event_handler.register(path, &new_block)
      end

      private
        def method_missing(meth, *a, &b)
          @event_handler.__send__(meth, *a, &b)
        end
    end

    # This class is an EM::Synchrony wrapper around a ZK::ZKEventMachine::Client
    #
    # It should behave exactly like a ZK::Client instance (when called in a
    # synchronous fashion), and one should look there for documentation about
    # the various methods
    #
    # @note this class is implemented as a wrapper instead of a subclass of Client
    #   so that it can support the unixisms like rm_rf and mkdir_p. The
    #   synchrony pattern of aliasing the base class methods and specializing for 
    #   synchrony didn't work in this case.
    #
    class SynchronyClient
      include ZK::Logging

      attr_reader :event_handler, :client

      # @overload new(client_instance)
      #   Wrap an existing ZK::ZKEventMachine::Client instance in an
      #   EM::Synchrony compatible way
      #   @param [ZK::ZKEventMachine::Client] client_instance an instance of Client to wrap
      # @overload new(host, opts={})
      #   Creates a new ZK::ZKEventMachine::Client instance to manage
      #   takes the same arguments as ZK::Client::Base
      def initialize(host, opts={})
        case host
        when Client
          @client = host
        when String
          @client = Client.new(host, opts)
        else
          raise ArgumentError, "argument must be either a ZK::ZKEventMachine::Client instance or a hostname:port string"
        end

        @event_handler = SynchronyEventHandlerWrapper.new(@client.event_handler)
      end

      %w[connect close close! get set create stat delete children get_acl set_acl mkdir_p rm_rf].each do |meth|
        class_eval(<<-EOMETH, __FILE__, __LINE__ + 1)
          def #{meth}(*args,&blk)
            sync!(@client.#{meth}(*args, &blk))
          end
        EOMETH
      end

      # @deprecated for backwards compatibility only
      def watcher
        event_handler
      end

      def exists?(path, opts={})
        stat(path, opts={}).exists?
      end

      # returns self
      def to_synchrony
        self
      end

      # returns the wrapped async client
      def to_async
        @client
      end

      protected
        # a modification of EM::Synchrony.sync to handle multiple callback arguments properly
        def sync(df)
          f = Fiber.current

          xback = proc do |*args|
            if f == Fiber.current
              return *args
            else
              f.resume(*args)
            end
          end

          df.callback(&xback)
          df.errback(&xback)

          Fiber.yield
        end

        # like sync, but if the deferred returns an exception instance, re-raises
        def sync!(deferred)
          rval = sync(deferred)
          raise rval if rval.kind_of?(Exception)
          rval
        end

      private
        def method_missing(meth, *a, &b)
          @client.__send__(meth, *a, &b)
        end
    end
  end
end

