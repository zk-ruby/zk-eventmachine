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

    def close_and_done!
      @zkem.close! { done }
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
      before do
        @paths = ['blah/foo', 'blah/bar', 'blah/bar/one', 'blah/bar/two', 'blah/quux'].map { |n| File.join(@base_path, n) }
        @paths.each { |n| @zk.mkdir_p(n) }
      end

      it %[should remove the paths recursively] do
        em do
          @zkem.connect do
            @zkem.rm_rf(@paths).callback do
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
            @zkem.rm_rf(@paths) do |exc|
              if exc.nil?
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



