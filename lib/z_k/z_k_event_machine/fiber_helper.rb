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

      def fiber
        if FiberHelper.root_fiber?
          Fiber.new { yield }.resume
        else
          yield
        end
      end
      alias ensure_fiber fiber
    end
  end
end

# initialize what we consider the root fiber on load.
ZK::ZKEventMachine::FiberHelper.root_fiber ||= Fiber.current

