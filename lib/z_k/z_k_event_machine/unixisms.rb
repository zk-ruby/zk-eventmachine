module ZK
  module ZKEventMachine
    module Unixisms
      def mkdir_p(paths, &block)
        dfr = Deferred::Default.new.tap do |my_dfr|
          Iterator.new(Array(paths).flatten.compact, 1).map(
            lambda { |path,iter|          # foreach
              d = _mkdir_p_dfr(path)
              d.callback { |p| iter.return(p) }
              d.errback  { |e| my_dfr.fail(e) }
            },
            lambda { |results| my_dfr.succeed(results) }     # after completion
          )
        end

        _handle_calling_convention(dfr, &block)
      end

      def rm_rf(paths, &blk)
        dfr = Deferred::Default.new.tap do |my_dfr|
          Iterator.new(Array(paths).flatten.compact, 1).each(
            lambda { |path,iter|          # foreach
              d = _rm_rf_dfr(path)
              d.callback { iter.next }
              d.errback  { |e| my_dfr.fail(e) }
            },
            lambda { my_dfr.succeed }     # after completion
          )
        end

        _handle_calling_convention(dfr, &blk)
      end

      def find(*paths, &block)
        raise NotImplementedError, "Coming soon"
      end

      def block_until_node_deleted(abs_node_path)
        raise NotImplementedError, "blocking does not make sense in EventMachine-land"
      end

      protected
        def _handle_calling_convention(dfr, &blk)
          return dfr unless blk
          dfr.callback { |*a| blk.call(nil, *a) }
          dfr.errback { |exc| blk.call(exc) }
          dfr
        end

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
                    Iterator.new(abspaths).each(
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

