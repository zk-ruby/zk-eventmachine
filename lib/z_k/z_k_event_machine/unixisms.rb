module ZK
  module ZKEventMachine
    module Unixisms
      def mkdir_p(paths, &block)
        dfr = Deferred::Default.new.tap do |my_dfr|
          Iterator.new(Array(paths).flatten.compact, 1).map(
            lambda { |path,iter|          # foreach
              d = _mkdir_p_dfr(path)
              d.callback { |p| iter.return(p) }
              d.errback do |e| 
                logger.debug { "main mkdir_p deferred erroring" }
                my_dfr.fail(e) 
              end
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

      # @private
      def find(*paths, &block)
        raise NotImplementedError, "Coming soon"
      end

      # @private
      def block_until_node_deleted(abs_node_path)
        raise NotImplementedError, "blocking does not make sense in EventMachine-land"
      end

      protected
        # @private
        def _handle_calling_convention(dfr, &blk)
          return dfr unless blk
          dfr.callback { |*a| blk.call(nil, *a) }
          dfr.errback { |exc| blk.call(exc) }
          dfr
        end

        # @private
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

        # @private
        def _mkdir_p_dfr(path)
          Deferred::Default.new.tap do |my_dfr|
            logger.debug { "_mkdir_p_dfr path: #{path}" }

            f = lambda do
              create(path, '').tap do |d|
                d.callback do |new_path|
                  logger.debug { "path #{path} created, new_path: #{new_path}" }
                  my_dfr.succeed(new_path)
                end # callback

                d.errback do |exc|
                  logger.debug { "got exception #{exc} creating path #{path}" }

                  case exc
                  when Exceptions::NodeExists
                    # this is the bottom of the stack, where we start bubbling back up
                    # or the first call, path already exists, return
                    logger.debug { "path #{path} exists" }
                    my_dfr.succeed(path)
                  when Exceptions::NoNode

                    # our node didn't exist now, so we try an recreate it after our
                    # parent has been created

                    p_path = File.dirname(path)

                    logger.debug { "mkdir_p(#{p_path})" }

                    parent_d = mkdir_p(p_path)            # set up our parent to be created

                    parent_d.callback do |parent_path|                # once our parent exists
                      logger.debug { "parent exists, now creating #{path}" }
                      create(path, '') do |exc,p|                     # create our path again
                        exc ? my_dfr.fail(exc) : my_dfr.succeed(p)    # pass our success or failure up the chain
                      end
                    end

                    parent_d.errback do |e|                           # if creating our parent fails
                      logger.debug { "creating parent of #{path} failed" }
                      my_dfr.fail(e)                                  # pass that along too
                    end
                  else
                    raise exc  # we should never hit this case
                  end
                end # errback
              end # create(path)
            end # f

            # if we're thinking of creating '/', then we should make sure it
            # exists, because create('/') will pass regardless in the evented
            # version
            #
            # this is terrible, and the driver should really return an exception in this case
            # but it doesn't in this callback case

            if path == '/'
              exists?(path) do |bool|
                if bool
                  f.call
                else
                  logger.debug { "our root does not exist! error!" }
                  my_dfr.fail(_non_existent_root!)
                end
              end
            else
              f.call
            end

          end # Deferred::Default.new.tap
        end

        def _non_existent_root!
          exc = Exceptions::NonExistentRootError.new("your root path '/' did not exist, are you chrooted to a non-existent path?")
          exc.set_backtrace(caller[0..-2])
          exc
        end
    end
  end
end

