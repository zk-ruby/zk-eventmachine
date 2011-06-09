module ZK
  module ZKEventMachine
    class Client < ZK::Client::Base
      include ZK::Logging

      DEFAULT_TIMEOUT = 10

      attr_reader :client

      # Takes same options as ZK::Client::Base
      def initialize(host, opts={})
        @host = host
        @event_handler = EventHandlerEM.new(self)
      end

      # open a ZK connection, attach it to the reactor. 
      # returns an EM::Deferrable that will be called when the connection is
      # ready for use
      def connect(&blk)
        @cnx = ZookeeperEM::Client.new(@host, DEFAULT_TIMEOUT, event_handler.get_default_watcher_block)
        @cnx.on_attached(&blk)
      end

      def event_handler
        @eh_proxy
      end
      alias :watcher :event_handler

      # get data at path, optionally enabling a watch on the node
      #
      # @returns [Callback] returns a Callback which is an EM::Deferred (so you
      #   can assign callbacks/errbacks) see Callback::Base for discussion
      #
      def get(path, opts={}, &block)
        Callback.new_get_cb(block) do |cb|
          client.get(path, opts.merge(:callback => cb))
        end
      end

      def create(path, data='', opts={}, &block)
        Callback.new_create_cb(block) do |cb|
          client.get(path, data, opts.merge(:callback => cb))
        end
      end

      def set(path, data, opts={}, &block)
        Callback.new_set_callback(block) do |cb|
          client.set(path, data, opts.merge(:callback => cb))
        end
      end

      def stat(path, opts={}, &block)
        Callback.new_stat_callback(block) do |cb|
          client.stat(path, opts.merge(:callback => cb))
        end
      end

      def delete(path, opts={}, &block)
        Callback.new_delete_callback(block) do |cb|
          client.delete(path, opts.merge(:callback => cb))
        end
      end

      def children(path, opts={}, &block)
        Callback.new_children_cb(block) do |cb|
          client.children(path, opts.merge(:callback => cb))
        end
      end

      def get_acl(path, opts={}, &block)
        Callback.new_get_acl_callback(block) do |cb|
          client.get_acl(path, opts.merge(:callback => cb))
        end
      end

      def set_acl(path, acls, opts={}, &block)
        Callback.new_set_acl_callback(block) do |cb|
          client.set_acl(path, acls, opts.merge(:callback => cb))
        end
      end
    end
  end
end

