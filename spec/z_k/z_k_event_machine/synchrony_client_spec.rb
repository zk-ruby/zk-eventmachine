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
            data, stat = @zksync.get(@base_path)
            data.should == @data
            stat.should be_kind_of(ZookeeperStat::Stat)
          end
        end

        it %[should raise an exception if the node does not exist] do
          with_zksync do
            lambda { @zksync.get('/thispathdoesnotexist') }.should raise_error(ZK::Exceptions::NoNode)
          end
        end
      end

      describe 'create' do
        describe 'success' do
          before do
            @path = [@base_path, 'foo'].join('/')
            @zk.delete(@path) rescue ZK::Exceptions::NoNode

            @data = 'this is data'
          end

          it 'should create a non-sequence node' do
            with_zksync do
              @zksync.create(@path, @data).should == @path
            end
          end

          it %[should create a sequence node] do
            with_zksync do
              @zksync.create(@path, @data, :sequence => true).should =~ /\A#{@path}\d+\Z/
            end
          end
        end
        
        describe 'failure' do
          it %[should barf if the node exists] do
            @path = [@base_path, 'foo'].join('/')
            @zk.create(@path, '')

            lambda { @zk.create(@path, '') }.should raise_error(ZK::Exceptions::NodeExists)
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

            @zksync.get(@path).first.should == @new_data
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

      describe 'delete' do
        it %[should delete the node] do
          @path = [@base_path, 'foo'].join('/')
          @data = 'this is data'
          @zk.create(@path, @data)

          with_zksync do
            @zksync.delete(@path)
          end

          @zk.exists?(@path).should be_false
        end

        it %[should raise NoNode exception if the node does not exist] do
          @path = [@base_path, 'foo'].join('/')
          @zk.delete(@path) rescue ZK::Exceptions::NoNode

          with_zksync do
            lambda { @zksync.delete(@path) }.should raise_error(ZK::Exceptions::NoNode)
          end
        end
      end

      describe 'children' do
        it %[should return the names of the children of the node] do
          @path = [@base_path, 'foo'].join('/')
          @child_1_path = [@path, 'child_1'].join('/')
          @child_2_path = [@path, 'child_2'].join('/')

          @data = 'this is data'
          @zk.create(@path, @data)
          @zk.create(@child_1_path, '')
          @zk.create(@child_2_path, '')

          with_zksync do
            children, stat = @zksync.children(@path)
            children.should be_kind_of(Array)
            children.length.should == 2
            children.should include('child_1')
            children.should include('child_2')

            stat.should be_instance_of(ZookeeperStat::Stat)
          end
        end

        it %[should raise NoNode if the node doesn't exist] do
          @path = [@base_path, 'foo'].join('/')
          @zk.delete(@path) rescue ZK::Exceptions::NoNode

          with_zksync do
            lambda { @zksync.children(@path) }.should raise_error(ZK::Exceptions::NoNode)
          end
        end
      end

      describe 'mkdir_p' do
        it %[should create the directory structure] do
          paths = [ "#{@base_path}/bar/baz", "#{@base_path}/foo/bar/quux" ]

          with_zksync do
            @zksync.mkdir_p(paths)
          end

          @zk.exists?("#{@base_path}/bar").should be_true
          @zk.exists?("#{@base_path}/bar/baz").should be_true
          @zk.exists?("#{@base_path}/foo").should be_true
          @zk.exists?("#{@base_path}/foo/bar").should be_true
          @zk.exists?("#{@base_path}/foo/bar/quux").should be_true
        end
      end

      describe 'rm_rf' do
        it %[should remove all paths listed] do
          @relpaths = ['disco/foo', 'prune/bar', 'fig/bar/one', 'apple/bar/two', 'orange/quux/c/d/e']

          @roots = @relpaths.map { |p| File.join(@base_path, p.split('/').first) }.uniq
          @paths = @relpaths.map { |n| File.join(@base_path, n) }

          @paths.each { |n| @zk.mkdir_p(n) }

          with_zksync do
            @zksync.rm_rf(@roots)
          end

          @roots.each { |n| @zk.exists?(n).should be_false }

          @zk.exists?(@base_path).should be_true
        end
      end
    end
  end
end

