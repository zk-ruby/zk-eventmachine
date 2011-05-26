module ZK
  module ZKEventMachine
    class Client
      attr_reader :client

      def initialize(zk_client)
        @client = zk_client
      end

      # get data at path, optionally enabling a watch on the node
      #
      # calls the given block on the reactor thread.
      #
      def get(path, opts={}, &block)
        cb = ZookeeperCallbacks::DataCallback.new do
          block.call(cb.return_code, cb.data, cb.stat, cb.context)

        end
      end
    end
  end
end

