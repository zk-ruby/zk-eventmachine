module ZK
  module ZKEventMachine
    # XXX: I've had to implement this in several places (not in this project),
    # need to come up with a common gem to hold this. This allows us to ensure
    # that we are executing in a non-root fiber, which is necessary for
    # Synchrony to work properly.
    #
    # @private
    module FiberHelper
      def self.root_fiber
        @@root_fiber = nil unless defined?(@@root_fiber)
        @@root_fiber
      end

      def self.root_fiber=(f)
        @@root_fiber = f
      end

      def self.root_fiber?
        root_fiber == Fiber.current
      end

#       module ClassMethods
#         # aliases the given methods and wraps them in an ensure_fiber call
#         def ensure_fiber(*syms)
#           syms.each do |sym|
#             meth_name = sym.to_s

#             aliased_meth_name = :"_ensure_fiber_#{meth_name}"

#             remove_method(aliased_meth_name) if method_defined?(aliased_meth_name)

#             unless method_defined?(aliased_meth_name)
#               alias_method(aliased_meth_name, sym)

#               class_eval(<<-EOS, __FILE__, __LINE__+1)
#                 def #{meth_name}(*a, &b)
#                   ensure_fiber do
#                     #{aliased_meth_name}(*a, &b)
#                   end
#                 end
#               EOS
#             end
#           end
#         end
#       end

      protected
        def fiber
          if FiberHelper.root_fiber?
            Fiber.new { yield }.resume
          else
            yield
          end
        end
        alias ensure_fiber fiber

        # a modification of EM::Synchrony.sync to handle multiple callback arguments properly
        def sync(df)
          f = Fiber.current

          xback = proc do |*args|
            if f == Fiber.current
              return *args
            else
              f.resume(*args)
            end
          end

          df.callback(&xback)
          df.errback(&xback)

          Fiber.yield
        end

        # like sync, but if the deferred returns an exception instance, re-raises
        def sync!(deferred)
          rval = sync(deferred)
          raise rval if rval.kind_of?(Exception)
          rval
        end
    end
  end
end

# initialize what we consider the root fiber on load.
ZK::ZKEventMachine::FiberHelper.root_fiber ||= Fiber.current

