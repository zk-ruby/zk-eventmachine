module ZK
  module ZKEventMachine
    module Unixisms

      def mkdir_p(path)
        deferred = Deferred::Default.new
        
        create(path, '', :mode => persistent) do |exc,p|
          case exc
          when Exceptions::NoNode
            mkdir_p(File.dirname(path)).callback do |p|
              begin
                deferred.succeed(create(path, '', :mode => persistent))
              rescue Exception => e
                deferred.fail(e)
              end
            end.errback do |e|
              deferred.fail(e)
            end
          when Exceptions::NodeExists
            # ok, we've finally gotten to a node that exists, so 
            deferred.succeed(p)
          end
        end

        deferred
      end

      def rm_rf(paths)
        raise NotImplementedError, "Coming soon"
      end

      def find(*paths, &block)
        raise NotImplementedError, "Coming soon"
      end

      def block_until_node_deleted(abs_node_path)
        raise NotImplementedError, "blocking does not make sense in EventMachine-land"
      end
    end
  end
end

