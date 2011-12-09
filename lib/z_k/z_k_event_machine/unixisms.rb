module ZK
  module ZKEventMachine
    module Unixisms
      include CallingConvention
      include FiberHelper

      def mkdir_p(paths, &block)
        dfr = Deferred::Default.new.tap do |my_dfr|
          EM::Iterator.new(Array(paths).flatten.compact, 1).map(
            lambda { |path,iter|          # foreach
              d = _mkdir_p_dfr(path)
              d.callback { |p| iter.return(p) }
              d.errback  { |e| my_dfr.fail(e) }
            },
            lambda { |results| my_dfr.succeed(results) }     # after completion
          )
        end

        handle_calling(dfr, &block)
      end

      def rm_rf(paths, &blk)
        dfr = Deferred::Default.new.tap do |my_dfr|
          EM::Iterator.new(Array(paths).flatten.compact, 1).each(
            lambda { |path,iter|          # foreach
              d = _rm_rf_dfr(path)
              d.callback { iter.next }
              d.errback  { |e| my_dfr.fail(e) }
            },
            lambda { my_dfr.succeed }     # after completion
          )
        end

        handle_calling(dfr, &blk)
      end

      def find(*paths, &block)
        raise NotImplementedError, "Coming soon"
      end

      class NodeDeletionDeferred
        include Deferred

        # The ZK::EventHandlerSubscription instance that we use for watching
        # for changes to the target node. We hold a reference here so that we
        # can cancel this in callbacks
        attr_accessor :subscription
      end
      
      # Will "block" the caller until the node is deleted. Synchrony/Fibers
      # will be used to provide the illusion of blocking semantics. Will raise
      # any exceptions that occur.
      def block_until_node_deleted(abs_node_path)
        ensure_fiber do
          sync!(defer_until_node_deleted(abs_node_path))
        end
      end

      # Returns a deferred that will fire when abs_node_path is deleted.
      # If abs_node_path does not exist when called, we succeed.
      #
      def defer_until_node_deleted(abs_node_path)
        NodeDeletionDeferred.new.tap do |nd_dfr|
          existence_check = proc do
            d = exists?(abs_node_path, :watch => true)
            d.callback do |node_exists|   # see if the node exists, set a watch (this method will be called)
              if node_exists              # if the node exists now, we have set a watch already
                logger.debug { "#{abs_node_path} exists, no-op wait for watch" }
              else
                logger.debug { "#{abs_node_path} does not exist, we succeed" }
                nd_dfr.succeed            # the node was deleted behind our back, success
              end
            end
            d.errback do |exc|
              nd_dfr.fail(exc)
            end
          end

          node_deletion_cb = lambda do |event|
            logger.debug { "node_deletion_cb received event: #{event.inspect}" }

            if event.node_deleted?
              # node deleted event received, success
              logger.debug { "node #{abs_node_path} was deleted, success!" }
              nd_dfr.succeed
            else
              logger.debug { "other node event, re-check" }
              existence_check.call
            end
          end

          nd_dfr.subscription = watcher.register(abs_node_path, &node_deletion_cb)

          # clean up the subscription
          nd_dfr.ensure_that do |*|
            if nd_dfr.subscription
              logger.debug { "cleaning up event subscription for #{abs_node_path}" }
              nd_dfr.subscription.unregister 
            end
          end

          existence_check.call
        end
      end

      protected
        def _rm_rf_dfr(path)
          Deferred::Default.new.tap do |my_dfr|
            delete(path) do |exc|
              case exc
              when nil, Exceptions::NoNode
                my_dfr.succeed
              when Exceptions::NotEmpty
                children(path) do |exc,chldrn,_|
                  case exc
                  when Exceptions::NoNode
                    my_dfr.succeed
                  when nil
                    abspaths = chldrn.map { |n| [path, n].join('/') }
                    EM::Iterator.new(abspaths).each(
                      lambda { |absp,iter|  
                        d = _rm_rf_dfr(absp)
                        d.callback  { |*| 
                          logger.debug { "removed #{absp}" }
                          iter.next
                        }
                        d.errback   { |e| 
                          logger.debug { "got failure #{e.inspect}" }
                          my_dfr.fail(e)   # this will stop the iteration
                        }
                      },
                      lambda { 
                        my_dfr.chain_to(_rm_rf_dfr(path))
                      }
                    )
                  else
                    my_dfr.fail(exc)
                  end
                end
              end
            end
          end
        end

        def _mkdir_p_dfr(path)
          Deferred::Default.new.tap do |my_dfr|
            d = create(path, '')

            d.callback do |new_path|
              my_dfr.succeed(new_path)
            end

            d.errback do |exc|
              case exc
              when Exceptions::NodeExists
                # this is the bottom of the stack, where we start bubbling back up
                # or the first call, path already exists, return
                my_dfr.succeed(path)
              when Exceptions::NoNode
                # our node didn't exist now, so we try an recreate it after our
                # parent has been created

                parent_d = mkdir_p(File.dirname(path))            # set up our parent to be created

                parent_d.callback do |parent_path|                # once our parent exists
                  create(path, '') do |exc,p|                     # create our path again
                    exc ? my_dfr.fail(exc) : my_dfr.succeed(p)    # pass our success or failure up the chain
                  end
                end

                parent_d.errback do |e|                           # if creating our parent fails
                  my_dfr.fail(e)                                  # pass that along too
                end
              end
            end
          end
        end
    end
  end
end

