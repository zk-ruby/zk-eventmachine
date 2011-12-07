module ZK
  module ZKEventMachine
    # @private
    module CallingConvention
      # handles the nodejs style callback if a block is given, or returns a
      # deferred if no block is given
      def handle_calling(dfr, &blk)
        return dfr unless blk
        dfr.callback { |*a| blk.call(nil, *a) }
        dfr.errback { |exc| blk.call(exc) }
        dfr
      end
      module_function :handle_calling
    end
  end
end

