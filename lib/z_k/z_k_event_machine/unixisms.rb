module ZK
  module ZKEventMachine
    module Unixisms
      def mkdir_p(path)
        Deferred::Default.new.tap do |dfr|
          create(path, '', :mode => persistent).callback do |path|
          end
        end
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

