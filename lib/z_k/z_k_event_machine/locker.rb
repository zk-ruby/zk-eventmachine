module ZK
  module ZKEventMachine
    module Locker
      # This class makes use of EM::Synchrony and the SynchronyClient, so the 
      # calling conventions are somewhat different than the rest of the library.
      #
      # These methods will appear to block the caller, but will actually use fibers
      # behind the scenes to relase control to EM when we are awaiting a reply.
      #
      # Another thing to note is that since this is synchronous-style,
      # *exceptions will be raised* and should be caught using a normal
      # begin/rescue/end block
      #
      #
      class LockerBase < ZK::Locker::LockerBase
        # XXX: it's totally lame that this doesn't share an implementaion w/ the ZK library
        #      due to a few methods here and there, this should be cleaned up and consolidated
        include ZK::Logging
        include FiberHelper

        # TODO: expose these in ZK as constants and just use them here
        ROOT_LOCK_NODE = '/_zklocking'
        SHARED_LOCK_PREFIX  = 'sh'.freeze
        EXCLUSIVE_LOCK_PREFIX = 'ex'.freeze

        attr_reader :zkem, :zksync, :path

        # XXX: root_lock_node is a terrible name
        # @private
        attr_reader :root_lock_node

        attr_reader :root_lock_path

        # @private
        def self.digit_from_lock_path(path) #:nodoc:
          path[/0*(\d+)$/, 1].to_i
        end

        def initialize(zkem_client, name, root_lock_node=nil)
          @zkem     = zkem_client
          @zksync   = @zkem.to_synchrony
          @path     = name
          @locked   = false
          @waiting  = false
          @root_lock_node = root_lock_node || ROOT_LOCK_NODE
          @root_lock_path = File.join(@root_lock_node, @path.gsub('/', '__'))
        end

        # do we hold the lock?
        def locked?
          false|@locked
        end

        # are we waiting to acquire the lock?
        def waiting?
          false|@waiting
        end

        protected
          def digit_from(path)
            self.class.digit_from_lock_path(path)
          end

          def create_root_path!(&blk)
            ensure_fiber do
              @zksync.mkdir_p(@root_lock_path)
            end
          end

          def create_lock_path!(prefix='lock')
            ensure_fiber do
              begin
                @lock_path = @zksync.create(File.join(@root_lock_path, prefix), '', :mode => :ephemeral_sequential)
                logger.debug { "got lock path #{@lock_path}" }
                @lock_path
              rescue Exceptions::NoNode
                create_root_path!
                retry
              end
            end
          end

          def cleanup_lock_path!(&blk)
            ensure_fiber do
              @zksync.delete(@lock_path)
              @zksync.delete(root_lock_path)
            end
          end
      end # LockerBase

      class SharedLocker < LockerBase
        def lock!(blocking=false)
          ensure_fiber do
            return true if locked?
            create_lock_path!(SHARED_LOCK_PREFIX)

            if got_read_lock?
            end
          end
        end

        def got_read_lock? #:nodoc:
          false if next_lowest_write_lock_num 
        rescue NoWriteLockFoundException
          true
        end

      end # SharedLocker
    end # Locker
  end # ZKEventMachine
end # ZK

