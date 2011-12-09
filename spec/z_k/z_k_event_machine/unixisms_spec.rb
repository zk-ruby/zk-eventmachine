require 'spec_helper'

module ZK::ZKEventMachine
  describe 'Unixisms' do
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
      @zk.rm_rf(@base_path)
      @zk.close!
    end

    def start_and_connect
      em do
        @zkem.connect { yield }
      end
    end

    def close_and_done!
      @zkem.close! { done }
    end

    describe 'defer_until_node_deleted' do
      before do
        @node_path = File.join(@base_path, 'watched')
      end

      describe 'succeed' do
        it %[should if the node doesn't exist] do
          @zk.exists?(@node_path).should be_false

          start_and_connect do
            @zkem.defer_until_node_deleted(@node_path).tap do |d|
              d.callback { close_and_done! }
              d.errback { |exc| raise exc }
            end
          end
        end

        it %[should callback when the node is deleted] do
          @zk.create(@node_path, '', :ephemeral => true)

          start_and_connect do
            @zkem.defer_until_node_deleted(@node_path).tap do |d|
              d.callback { close_and_done! }
              d.errback { |e| raise e }
            end

            EM.next_tick do
              @zkem.delete(@node_path).errback { |e| raise e }
            end
          end
        end

        # there is a tricky race-condition that i'm 99% sure is covered by
        # the pattern we've consitently been following, but we should attempt 
        # to write tests to cover every branch
      end
    end

    describe 'block_until_node_deleted' do
      include FiberHelper
      include ZK::Logging

      before do
        @node_path = File.join(@base_path, 'watched')
      end

      it %[should succeed if the node doesn't exist] do
        @zk.exists?(@node_path).should be_false

        start_and_connect do
          ensure_fiber do
            @zkem.block_until_node_deleted(@node_path)
            close_and_done!
          end
        end
      end

      it %[should wait until the node is deleted and then return] do
        @zk.create(@node_path, '', :ephemeral => true)

        start_and_connect do
          EM.add_timer(0.1) do
            logger.info { "timer fired!" }
            @zkem.delete(@node_path).callback do
              logger.info { "deleted node #{@node_path}" }
            end.errback { |e| raise e }
          end

          ensure_fiber do
            logger.info { "waiting until #{@node_path} is deleted" }
            @zkem.block_until_node_deleted(@node_path)
            logger.info { "returned from block_until_node_deleted" }
            @zk.exists?(@node_path).should be_false
            close_and_done!
          end
        end
      end
    end

    describe 'mkdir_p' do
      before do
        @bogus_paths = [
          [@base_path, 'bogus', 'path', 'to', 'qwer'].join('/'),
          [@base_path, 'bogus', 'path', 'to', 'somethingelse'].join('/')
        ]
      end

      it %[should create the path recursively] do
        @zk.exists?(@bogus_paths.first).should be_false

        em do
          @zkem.connect do
            @zkem.mkdir_p(@bogus_paths.first).callback do |p|
              p.first.should == @bogus_paths.first
              close_and_done!
            end.errback do |e|
              raise e
            end
          end
        end
      end

      it %[should not error on a path that already exists] do
        @zk.mkdir_p(@bogus_paths.first)

        em do
          @zkem.connect do
            @zkem.mkdir_p(@bogus_paths.first) do |exc,p|
              exc.should be_nil
              p.first.should == @bogus_paths.first
              close_and_done!
            end
          end
        end
      end

      it %[should take an array of paths] do
        @bogus_paths.each do |p|
          @zk.exists?(p).should be_false
        end

        em do
          @zkem.connect do
            @zkem.mkdir_p(@bogus_paths) do |exc,paths|
              exc.should be_nil
              paths.should be_kind_of(Array)
              @bogus_paths.each { |p| paths.should include(p) }
              close_and_done!
            end
          end
        end
      end
    end

    describe 'rm_rf' do
      em_before do
        @relpaths = ['disco/foo', 'prune/bar', 'fig/bar/one', 'apple/bar/two', 'orange/quux/c/d/e']

        @roots = @relpaths.map { |p| File.join(@base_path, p.split('/').first) }.uniq
        @paths = @relpaths.map { |n| File.join(@base_path, n) }

        @paths.each { |n| @zk.mkdir_p(n) }
      end

      it %[should remove the paths recursively] do
        em do
          @zkem.connect do
            @zkem.rm_rf(@roots).callback do
              @roots.each { |p| @zk.exists?(p).should be_false }
              close_and_done!
            end.errback do |exc|
              raise exc
            end
          end
        end
      end # it

      it %[should use the nodejs style if a block is given] do
        em do
          @zkem.connect do
            @zkem.rm_rf(@roots) do |exc|
              if exc.nil?
                @roots.each { |p| @zk.exists?(p).should be_false }
                close_and_done!
              else
                raise exc
              end
            end
          end
        end
      end
    end
  end
end



