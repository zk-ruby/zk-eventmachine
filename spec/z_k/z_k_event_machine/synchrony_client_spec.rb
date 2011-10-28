require 'spec_helper'

module ZK
  module ZKEventMachine
    describe 'SynchronyClient' do
      include EventedSpec::SpecHelper
      default_timeout 2.0

      def em_synchrony(&blk)
        em do
          EM.next_tick { Fiber.new { blk.call }.resume }
        end
      end

      def with_zksync
        em_synchrony do
          begin
            @zksync.connect
            yield @zksync
          ensure
            @zksync.close!
            done
          end
        end
      end

      before do
        @zk = ::ZK.new
        @base_path = '/zk-em-testing'
        @zk.rm_rf(@base_path)
        @zk.mkdir_p(@base_path)
        @zksync = ZK::ZKEventMachine::SynchronyClient.new('localhost:2181')
      end

      after do
        @zk.rm_rf(@base_path)
        @zk.close!
      end

      describe 'connect' do
        it %[should connect to zookeeper] do
          logger.debug { "about to call connect" }
          em_synchrony do
            @zksync.connect

            lambda { @zksync.get(@base_path) }.should_not raise_error

            done { @zksync.close }
          end
        end
      end

      describe 'get' do
        before do
          @data = "this is data"
          @zk.set(@base_path, @data)
        end

        it %[should get the data and stat of a node that exists] do
          with_zksync do
            data = @zksync.get(@base_path)
            data.should == @data
          end
        end

        it %[should raise an exception if the node does not exist] do
          with_zksync do
            lambda { @zksync.get('/thispathdoesnotexist') }.should raise_error(ZK::Exceptions::NoNode)
          end
        end
      end

      describe 'set' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @data = 'this is data'
          @new_data = 'this is better data'
          @zk.create(@path, @data)
          @orig_stat = @zk.stat(@path)
        end

        it %[should set the data and return a stat] do
          with_zksync do
            stat = @zksync.set(@path, @new_data)
            stat.should be_instance_of(ZookeeperStat::Stat)
            stat.version.should > @orig_stat.version

            @zksync.get(@path).should == @new_data
          end
        end

        it %[should raise NoNode if the node doesn't exist] do
          with_zksync do
            lambda { @zksync.set('/thispathdoesnotexist', 'data') }.should raise_error(ZK::Exceptions::NoNode)
          end
        end

        it %[should raise BadVersion if the version is wrong] do
          with_zksync do
            @zksync.set(@path, @new_data)
            lambda { @zksync.set(@path, 'otherdata', :version => @orig_stat.version) }.should raise_error(ZK::Exceptions::BadVersion)
          end
        end
      end

      describe 'exists?' do
        before do
          @path = [@base_path, 'foo'].join('/')
          @data = 'this is data'
        end

        it %[should return true if the node exists] do
          @zk.create(@path, @data)

          with_zksync do
            @zksync.exists?(@path).should be_true
          end
        end

        it %[should return false if the node doesn't exist] do
          with_zksync do
            @zksync.exists?(@path).should be_false
          end
        end
      end

      describe 'stat' do
        describe 'success' do
          before do
            @path = [@base_path, 'foo'].join('/')
            @data = 'this is data'
            @zk.create(@path, @data)
            @orig_stat = @zk.stat(@path)
          end

          it %[should get the stat] do
            with_zksync do
              stat = @zksync.stat(@path)

              stat.should_not be_nil
              stat.should == @orig_stat
              stat.should be_instance_of(ZookeeperStat::Stat)
            end
          end
        end

        describe 'non-existent node' do
          before do
            @path = [@base_path, 'foo'].join('/')
            @zk.delete(@path) rescue ZK::Exceptions::NoNode
          end

          it %[should not be an error] do
            with_zksync do
              stat = @zksync.stat(@path)
              stat.should_not be_nil
              stat.exists?.should be_false
              stat.should be_instance_of(ZookeeperStat::Stat)
            end
          end
        end
      end
    end
  end
end

