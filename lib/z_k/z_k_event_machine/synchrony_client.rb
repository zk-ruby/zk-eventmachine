module ZK
  module ZKEventMachine
    # This class is an EM::Synchrony wrapper around a ZK::ZKEventMachine::Client
    #
    # It should behave exactly like a ZK::Client instance (when called in a
    # synchronous fashion), and one should look there for documentation about
    # the various methods
    #
    class SynchronyClient
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
      end

      %w[connect close close! get set create stat delete children get_acl set_acl mkdir_p rm_rf].each do |meth|
        class_eval(<<-EOMETH, __FILE__, __LINE__ + 1)
          def #{meth}(*args,&blk)
            sync!(@client.#{meth}(*args, &blk))
          end
        EOMETH
      end

      def exists?(path, opts={})
        stat(path, opts={}).exists?
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
    end
  end
end

