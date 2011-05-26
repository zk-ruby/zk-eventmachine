module ZK
  module ZKEventMachine
    # some improvements (one hopes) around the zookeeper gem's somewhat (ahem)
    # minimal Callback class
    #
    module Callback
      
      # Used by ZooKeeper to return an asynchronous result. Semantics depend on
      # the way you use this class. If callbacks or errbacks are set on the
      # instance, they will be called with just the data returned from the call
      # (much like their synchronous versions). If no callbacks/errbacks are
      # set, then the block is called with a ZK::Exceptions::KeeperException
      # instance or nil, then the rest of the arguments defined for that
      # callback type (see subclass documentation for details)
      #
      class Base
        include EM::Deferrable

        # set the result keys that should be used by node_style_result and to
        # call the deferred_style_result blocks
        #
        def self.async_result_keys(*syms)
          if syms.empty? 
            @async_result_keys
          else
            @async_result_keys = syms.map { |n| n.to_sym }
          end
        end

        def initialize(&block)
          @block = block
        end

        # register a block that should be called (node.js style) with the
        # results
        #
        # @note replaces the block given to #new 
        #
        def on_result(&block)
          @block = block
        end

        # ZK will call this instance with a hash of data, which is the result
        # of the asynchronous call. Depending on the style of callback in use,
        # we take the appropriate actions
        #
        # delegates to #deferred_style_result or #node_style_result
        def call(hash)
          @block.nil? ? deferred_style_result(hash) : node_style_result(hash)
        end

        # returns true if the request was successful (if return_code was Zookeeper::ZOK)
        #
        # @param [Hash] hash the result of the async call 
        # 
        # @returns [true, false] for success, failure 
        def success?(hash)
          hash[:rc] == Zookeeper::ZOK
        end

        # Returns an instance of a sublcass ZK::Exceptions::KeeperException
        # based on the asynchronous return_code.
        #
        # facilitates using case statements for error handling
        #
        # @param [Hash] hash the result of the async call 
        #
        # @raise [RuntimeError] if the return_code is not known by ZK (this should never
        #   happen and if it does, you should report a bug)
        #
        # @return [ZK::Exceptions::KeeperException, nil] subclass based on
        #   return_code if there was an error, nil otherwise
        #
        def exception_for(hash)
          return nil if success?(hash)
          return_code = hash.fetch(:rc)
          ZK::Exceptions::KeeperException.by_code(return_code).new
        end

        # slight modification to EM::Deferrable, 
        #
        # @returns [self] to allow for chaining
        #
        def callback(&block)
          super(&block)
          self
        end

        # @see #callback
        def errback(&block)
          super(&block)
          self
        end

        # @abstract should call set_deferred_status with the appropriate args
        #   for the result and type of call
        def deferred_style_result(hash)
          # ensure this calls the callback on the reactor
          EM.next_tick do
            if success?(hash)
              succeed(*hash.values_at(*async_result_keys))
            else
              fail(exception_for(hash))
            end
          end
        end

        # call the user block with the correct Exception class as the first arg
        # (or nil if no error) and then the appropriate args for the type of
        # asynchronous call
        def node_style_result(hash)
          # call this on the reactor
          EM.next_tick do
            @block.call(exception_for(hash), *hash.values_at(*async_result_keys))
          end
        end

        protected
          def async_result_keys
            self.class.async_result_keys
          end
      end

      # used with Client#get call
      class DataCallback < Base
        async_result_keys :data, :stat
      end

      # used with Client#children call
      class ChildrenCallback < Base
        async_result_keys :strings, :stat
      end

      # used with Client#create
      class StringCallback < Base
        async_result_keys :string
      end

      # used with Client#stat and Client#exists?
      class StatCallback < Base
        async_result_keys :stat
      end

      # used with Client#delete and Client#set_acl
      class VoidCallback < Base
      end

      # used with Client#get_acl
      class ACLCallback < Base
        async_result_keys :acl, :stat
      end
    end
  end
end

