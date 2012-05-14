require 'spec_helper'

module ZK::ZKEventMachine
  describe 'EventHandlerEM' do
    include EventedSpec::SpecHelper
    default_timeout 2.0

    before do
      @zk = ::ZK.new
      @base_path = '/zk-em-testing'
      @zk.rm_rf(@base_path)
      @zk.mkdir_p(@base_path)
      @zkem = ZK::ZKEventMachine::Client.new('localhost:2181')
    end

    after do
      mute_logger do
        @zk.rm_rf(@base_path)
        @zk.close!
      end
    end

    # this is a test of event delivery in general, not just of the
    # EventHandlerEM implementation

    describe 'data event' do
      include EventedSpec::EMSpec

      before do
        @path = "#{@base_path}/blah"
        @data = "this is data"
        @new_data = "this is other data"

        @child_path = [@path, 'child'].join('/')
      end

      it %[should call the callback when the data of a watched node changes] do
        @zkem.connect do
          @zkem.event_handler.register(@path) do |event|
            EM.reactor_thread?.should be_true
            event.should be_node_changed
            @zkem.close! { done }
          end

          common_eb = lambda { |exc| raise exc }

          @zkem.create(@path, @data) do |exc,path|
            raise exc if exc

            @zkem.stat(@path, :watch => true) do |e,*a| 
              raise e if e

              @zkem.set(@path, @new_data) do |e,*a|
                raise e if e
              end
            end
          end
        end
      end

      it %[should call the callback when the children of the watched node change] do
        @zkem.connect do
          @zkem.event_handler.register(@path) do |event|
            EM.reactor_thread?.should be_true
            event.should be_node_child
            @zkem.close! { done }
          end

          eb_raise = lambda { |e| raise e if e }

          @zkem.create(@path, @data).callback { |*|
            @zkem.children(@path, :watch => true).callback { |ary,stat|
              logger.debug { "called back with: #{ary.inspect}" }
              ary.should be_empty
              stat.should be_kind_of(Zookeeper::Stat)

              @zkem.create(@child_path, '').callback { |p|
                p.should == @child_path

              }.errback(&eb_raise)
            }.errback(&eb_raise)
          }.errback(&eb_raise)
        end
      end # it

      it %[should call back the registered block when the node is deleted] do
        @zkem.connect do
          @zkem.event_handler.register(@path) do |event|
            EM.reactor_thread?.should be_true
            event.should be_node_deleted
            @zkem.close! { done }
          end

          eb_raise = lambda { |e| raise e if e }

          @zkem.create(@path, @data).callback do |*|
            @zkem.stat(@path, :watch => true).callback do |*|
              @zkem.delete(@path).errback(&eb_raise)

            end.errback(&eb_raise)
          end.errback(&eb_raise)
        end
      end
    end
  end
end

