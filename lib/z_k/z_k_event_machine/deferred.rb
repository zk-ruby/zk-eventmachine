module ZK
  module ZKEventMachine
    module Deferred
      include EM::Deferrable

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

      # adds the block to both the callback and errback chains
      def ensure_that(&block)
        callback(&block)
        errback(&block)
      end

      class Default
        include ZK::ZKEventMachine::Deferred
      end
    end
  end
end

