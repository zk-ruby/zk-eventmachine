module ZK
  module ZKEventMachine
    class Client
      attr_reader :client

      def initialize(zk_client)
        @client = zk_client
      end

      # get data at path, optionally enabling a watch on the node
      #
      # @returns [Callback] returns a Callback which is an EM::Deferred (so you
      #   can assign callbacks/errbacks) see Callback::Base for discussion
      #
      def get(path, opts={}, &block)
        Callback.new_data_cb(block) do |cb|
          client.get(path, opts.merge(:callback => cb))
        end
      end

      def create(path, data='', opts={}, &block)
        Callback.new_string_cb(block) do |cb|
          client.get(path, data, opts.merge(:callback => cb))
        end
      end

      def set(path, data, opts={}, &block)
        Callback.new_stat_callback(block) do |cb|
          client.set(path, data, opts.merge(:callback => cb))
        end
      end

      def stat(path, opts={}, &block)
        Callback.new_stat_callback(block) do |cb|
          client.stat(path, opts.merge(:callback => cb))
        end
      end

      def delete(path, opts={}, &block)
        Callback.new_void_callback(block) do |cb|
          client.delete(path, opts.merge(:callback => cb))
        end
      end

      def children(path, opts={}, &block)
        Callback.new_children_cb(block) do |cb|
          client.children(path, opts.merge(:callback => cb))
        end
      end

      def get_acl(path, opts={}, &block)
        Callback.new_acl_callback(block) do |cb|
          client.get_acl(path, opts.merge(:callback => cb))
        end
      end

      def set_acl(path, acls, opts={}, &block)
        Callback.new_void_callback(block) do |cb|
          client.set_acl(path, acls, opts.merge(:callback => cb))
        end
      end
    end
  end
end

