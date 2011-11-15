module ZK
  module ZKEventMachine
    class Client < ZK::Client::Base
      include ZK::Logging
      include Unixisms

      DEFAULT_TIMEOUT = 10

      # allows the synchrony client to muck with this
      # @private
      attr_writer :event_handler, :synchrony_client

      # Takes same options as ZK::Client::Base
      def initialize(host, opts={})
        @host = host
        @close_deferred = Deferred::Default.new
        @connection_lost_deferred = Deferred::Default.new
        @event_handler = EventHandlerEM.new(self)
      end

      def on_close(&blk)
        @close_deferred.callback(&blk) if blk
        @close_deferred
      end

      # open a ZK connection, attach it to the reactor. 
      # returns an EM::Deferrable that will be called when the connection is
      # ready for use
      def connect(&blk)
        # XXX: maybe move this into initialize, need to figure out how to schedule it properly
        @cnx ||= ZookeeperEM::Client.new(@host, DEFAULT_TIMEOUT, event_handler.get_default_watcher_block)
#         @cnx.on_attached do
#           $stderr.puts "@cnx, obj_id: %x" % [@cnx.object_id]
#         end
        @cnx.on_attached(&blk)
      end

      # @private
      # XXX: move this down into ZK::Client::Base
      def connected?
        @cnx and @cnx.connected?
      end

      # If we get a ZK::Exceptions::ConnectionLoss exeption back from any call,
      # we will call back any handlers registered here with the exception
      # instance as the argument
      #
      # once this deferred has been fired, it will be replaced with a new
      # deferred, so callbacks must be re-registered
      # 
      def on_connection_lost(&blk)
        @connection_lost_deferred.callback(&blk) if blk
        @connection_lost_deferred
      end

      def reopen(*a)
        raise NotImplementedError, "reoopen is not implemented for the eventmachine version of the client"
      end
      
      def close!(&blk)
        on_close(&blk)

        if @cnx
          logger.debug { "#{self.class.name}: in close! clearing event_handler" }
          event_handler.clear!

          logger.debug { "#{self.class.name}: calling @cnx.close" }
          @cnx.close do
            # fire the on_close handler in next_tick so that @cnx is nil
            EM.next_tick do
              logger.debug { "firing on_close handler" }
              on_close.succeed
            end
            @cnx = nil
          end
        else
          on_close.succeed
        end

        on_close
      end
      alias :close :close!

      # get data at path, optionally enabling a watch on the node
      #
      # @returns [Callback] returns a Callback which is an EM::Deferred (so you
      #   can assign callbacks/errbacks) see Callback::Base for discussion
      #
      def get(path, opts={}, &block)
        Callback.new_get_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, opts.merge(:callback => cb))
        end
      end

      def create(path, data='', opts={}, &block)
        Callback.new_create_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, data, opts.merge(:callback => cb))
        end
      end

      def set(path, data, opts={}, &block)
        Callback.new_set_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, data, opts.merge(:callback => cb))
        end
      end

      def stat(path, opts={}, &block)
        cb_style = opts.delete(:cb_style) { |_| 'stat' }

        meth = :"new_#{cb_style}_cb"

        Callback.__send__(meth, block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, opts.merge(:callback => cb))
        end
      end

      def exists?(path, opts={}, &block)
        stat(path, opts.merge(:cb_style => 'exists'), &block)
      end

      def delete(path, opts={}, &block)
        Callback.new_delete_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, opts.merge(:callback => cb))
        end
      end

      def children(path, opts={}, &block)
        Callback.new_children_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, opts.merge(:callback => cb))
        end
      end

      def get_acl(path, opts={}, &block)
        Callback.new_get_acl_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, opts.merge(:callback => cb))
        end
      end

      def set_acl(path, acls, opts={}, &block)
        Callback.new_set_acl_cb(block) do |cb|
          cb.errback(&method(:connection_lost_hook))
          super(path, acls, opts.merge(:callback => cb))
        end
      end

      # returns an EM::Synchrony compatible wrapper around this client
      def to_synchrony
        @synchrony_client ||= SynchronyClient.new(self)
      end

      # returns self
      def to_async
        self
      end

    protected
      def connection_lost_hook(exc)
        if exc and exc.kind_of?(ZK::Exceptions::ConnectionLoss)
          dfr, @connection_lost_deferred = @connection_lost_deferred, Deferred::Default.new
          dfr.succeed(exc)
        end
      end
    end
  end
end

