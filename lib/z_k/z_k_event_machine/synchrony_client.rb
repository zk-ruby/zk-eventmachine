module ZK
  module ZKEventMachine
    class SynchronyClient < Client

      %w[connect close close! get set create stat delete children get_acl set_acl].each do |meth|
        ameth_name = :"a#{meth}"

        alias_method(ameth_name, meth.to_sym) unless method_defined?(ameth_name)

        class_eval(<<-EOMETH, __FILE__, __LINE__ + 1)
          def #{meth}(*args,&blk)
            logger.debug { "calling a#{meth}" }
            deferred = a#{meth}(*args, &blk)
            logger.debug { "EM::Synchrony.sync(\#{deferred.inspect})" }

            sync!(deferred)
          end
        EOMETH
      end

      alias_method(:aexists?, :exists?) unless method_defined?(:aexists?)

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

