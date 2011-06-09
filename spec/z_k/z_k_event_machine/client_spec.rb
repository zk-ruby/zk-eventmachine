require 'spec_helper'

module ZK::ZKEventMachine
  describe 'Client' do
    include EventedSpec::SpecHelper

    default_timeout 2.0

    before do
      @zk = ::ZK.new
      @base_path = '/zk-em'
      @zk.rm_rf(@base_path)
      @zk.mkdir_p(@base_path)
      @zkem = ZK::ZKEventMachine::Client.new('localhost:2181')
    end

    after do
      @zk.rm_rf(@base_path)
      @zk.close!
    end

    context 'connect' do
      it %[should return a deferred that fires when connected and then close] do
        em do
          @zkem.connect do
            true.should be_true
            @zkem.close! { done }
          end
        end
      end
    end

    context 'get' do
      before do
        @path = [@base_path, 'foo'].join('/')
        @data = 'this is data'
        @zk.create(@path, @data)
      end

      it 'should get the data and call the callback' do
        @cb_args = @exc = nil

        em do
          @zkem.connect do
            dfr = @zkem.get(@path)

            dfr.callback do |*a| 
              logger.debug { "got callback with #{a.inspect}" }
              a.should_not be_empty
              a.first.should == @data
              a.last.should be_instance_of(ZookeeperStat::Stat)
              EM.reactor_thread?.should be_true
              @zkem.close! { done }
            end

            dfr.errback  do |exc| 
              logger.debug { "got errback" }
              @exc = exc
            end
          end
        end
      end

      it 'should get the data and do a node-style callback' do
        em do
          @zkem.connect do
            @zkem.get(@path) do |exc,data,stat|
              exc.should be_nil
              data.should == @data
              stat.should be_instance_of(ZookeeperStat::Stat)
              EM.reactor_thread?.should be_true
              done
            end
          end
        end
      end
    end
  end
end


