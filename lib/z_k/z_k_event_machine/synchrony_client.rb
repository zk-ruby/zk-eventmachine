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
        def sync!(deferred)
          rval = EM::Synchrony.sync(deferred)
          raise rval if rval.kind_of?(Exception)
          rval
        end
    end
  end
end

