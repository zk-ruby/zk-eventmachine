module ZK
  module ZKEventMachine
    module Unixisms

      class RecursiveRemover
        include Deferred

        def self.rm(path)
          new(path).rm
        end

        def initialize(path)
          @path = path
          @child_abspaths = []
        end

        def rm
          d = children(@path)

          d.callback do |chld_list,_|
            @child_abspaths = chld_list.map { |cname| File.join(@path, cname) }
            rm_my_kids
          end

          self
        end # rm

        def rm_my_kids
          if @child_abspaths.empty?
            self.succeed()
            return
          end

          ca = @child_abspaths.shift

          d = self.class.rm(ca)

          d.callback do
            @child_abspaths.delete(ca)
            rm_my_kids
          end

          d.errback do |e|
            unless e.kind_of?(ZK::Exceptions::NoNode)
              self.fail(e)
            end
          end
        end
      end # RecursiveRemover

      def mkdir_p(path, &block)
        _handle_calling_convention(_mkdir_p_dfr(path), &block)
      end

      def rm_rf(paths)
        _rm_rf_dfr(paths)
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
          nil
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

