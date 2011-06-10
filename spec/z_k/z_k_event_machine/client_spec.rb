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

    describe 'connect' do
      it %[should return a deferred that fires when connected and then close] do
        em do
          @zkem.connect do
            true.should be_true
            @zkem.close! { done }
          end
        end
      end
    end

    describe 'get' do
      describe 'success' do
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
                raise exc
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
                @zkem.close! { done }
              end
            end
          end
        end
      end # success

      describe 'failure' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @zk.delete(@path) rescue ZK::Exceptions::NoNode
        end

        it %[should call the errback in deferred style] do
          em do
            @zkem.connect do
              d = @zkem.get(@path)

              d.callback do
                raise "Should not have been called"
              end

              d.errback do |exc|
                exc.should be_kind_of(ZK::Exceptions::NoNode)
                @zkem.close! { done }
              end
            end
          end
        end

        it %[should have NoNode as the first argument to the block] do
          em do
            @zkem.connect do
              @zkem.get(@path) do |exc,*a|
                exc.should be_kind_of(ZK::Exceptions::NoNode)
                @zkem.close! { done }
              end
            end
          end
        end
      end # failure
    end # get

    describe 'create' do
      describe 'success' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @zk.delete(@path) rescue ZK::Exceptions::NoNode

          @data = 'this is data'
        end

        describe 'non-sequence node' do
          it 'should create the node and call the callback' do
            em do
              @zkem.connect do
                d = @zkem.create(@path, @data)

                d.callback do |*a| 
                  logger.debug { "got callback with #{a.inspect}" }
                  a.should_not be_empty
                  a.first.should == @path
                  EM.reactor_thread?.should be_true
                  @zkem.close! { done }
                end

                d.errback  do |exc| 
                  raise exc
                end
              end
            end
          end

          it 'should get the data and do a node-style callback' do
            em do
              @zkem.connect do
                @zkem.create(@path, @data) do |exc,created_path|
                  exc.should be_nil
                  created_path.should == @path
                  EM.reactor_thread?.should be_true
                  @zkem.close! { done }
                end
              end
            end
          end
        end # non-sequence node

        describe 'sequence node' do
          it 'should create the node and call the callback' do
            em do
              @zkem.connect do
                d = @zkem.create(@path, @data, :sequence => true)

                d.callback do |*a| 
                  logger.debug { "got callback with #{a.inspect}" }
                  a.should_not be_empty
                  a.first.should =~ /#{@path}\d+$/
                  EM.reactor_thread?.should be_true
                  @zkem.close! { done }
                end

                d.errback  do |exc| 
                  raise exc
                end
              end
            end
          end
        end
      end # success

      describe 'failure' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @zk.create(@path, '')
        end

        it %[should call the errback in deferred style] do
          em do
            @zkem.connect do
              d = @zkem.create(@path, '')

              d.callback do
                raise "Should not have been called"
              end

              d.errback do |exc|
                exc.should be_kind_of(ZK::Exceptions::NodeExists)
                @zkem.close! { done }
              end
            end
          end
        end

        it %[should have exception as the first argument to the block] do
          em do
            @zkem.connect do
              @zkem.create(@path, '') do |exc,*a|
                exc.should be_kind_of(ZK::Exceptions::NodeExists)
                @zkem.close! { done }
              end
            end
          end
        end
      end # failure
    end # create


    describe 'set' do
      describe 'success' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @data = 'this is data'
          @new_data = 'this is better data'
          @zk.create(@path, @data)
          @orig_stat = @zk.stat(@path)
        end

        it 'should set the data and call the callback' do
          em do
            @zkem.connect do
              dfr = @zkem.set(@path, @new_data)

              dfr.callback do |stat| 
                stat.should be_instance_of(ZookeeperStat::Stat)
                stat.version.should > @orig_stat.version
                EM.reactor_thread?.should be_true

                @zkem.get(@path) do |_,data|
                  data.should == @new_data
                  @zkem.close! { done }
                end
              end

              dfr.errback  do |exc| 
                raise exc
              end
            end
          end
        end

        it 'should set the data and do a node-style callback' do
          em do
            @zkem.connect do
              @zkem.set(@path, @new_data) do |exc,stat|
                exc.should be_nil
                stat.should be_instance_of(ZookeeperStat::Stat)
                EM.reactor_thread?.should be_true

                @zkem.get(@path) do |_,data|
                  data.should == @new_data
                  @zkem.close! { done }
                end
              end
            end
          end
        end
      end # success

      describe 'failure' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @zk.delete(@path) rescue ZK::Exceptions::NoNode
        end

        it %[should call the errback in deferred style] do
          em do
            @zkem.connect do
              d = @zkem.set(@path, '')

              d.callback do
                raise "Should not have been called"
              end

              d.errback do |exc|
                exc.should be_kind_of(ZK::Exceptions::NoNode)
                @zkem.close! { done }
              end
            end
          end
        end

        it %[should have NoNode as the first argument to the block] do
          em do
            @zkem.connect do
              @zkem.set(@path, '') do |exc,_|
                exc.should be_kind_of(ZK::Exceptions::NoNode)
                @zkem.close! { done }
              end
            end
          end
        end
      end # failure
    end # set

  end
end


