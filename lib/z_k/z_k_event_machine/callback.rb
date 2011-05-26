module ZK
  module ZKEventMachine
    # some improvements (one hopes) around the zookeeper gem's somewhat (ahem)
    # minimal Callback class
    #
    module Callback
      
      class Base
        include EM::Deferred

        def initialize

        end

        # returns true if the request was successful (if return_code was Zookeeper::ZOK)
        # 
        # @returns [true, false] for success, failure 
        def success?
          return_code == Zookeeper::ZOK
        end

        # Returns an instance of a sublcass ZK::Exceptions::KeeperException
        # based on the asynchronous return_code.
        #
        # facilitates using case statements for error handling
        #
        # @raise [RuntimeError] if the return_code is not known by ZK (this should never
        #   happen and if it does, you should report a bug)
        #
        # @return [ZK::Exceptions::KeeperException, nil] subclass based on
        #   return_code if there was an error, nil otherwise
        #
        def exception
          return nil if success?
          ZK::Exceptions::KeeperException.by_code(return_code).new
        end
      end

      class DataCallback < ZookeeperCallbacks::DataCallback
        include Conveniences
      end

      class ChildrenCallback < ZookeeperCallbacks::StringsCallback
        include Conveniences
      end

      class StringCallback < ZookeeperCallbacks::StringCallback
        include Conveniences
      end

      class StatCallback < ZookeeperCallbacks::StatCallback
        include Conveniences
      end

      class VoidCallback < ZookeeperCallbacks::VoidCallback
        include Conveniences
      end

      class ACLCallback < ZookeeperCallbacks::ACLCallback
        include Conveniences
      end
    end
  end
end

