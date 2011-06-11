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

    em_after do
      @zkem.close!
    end

    describe 'mkdir_p' do
      before do
        @bogus_path = [@base_path, 'bogus', 'path', 'to', 'qwer'].join('/')
      end

      it %[should create the path recursively] do
        @zk.exists?(@bogus_path).should be_false

        em do
          @zkem.connect do
            @zkem.mkdir_p(@bogus_path).callback do |p|
              p.should == @bogus_path
              done
            end.errback do |e|
              raise e
            end
          end
        end
      end

      it %[should not error on a path that already exists] do
        @zk.mkdir_p(@bogus_path)

        em do
          @zkem.connect do
            @zkem.mkdir_p(@bogus_path) do |exc,p|
              exc.should be_nil
              p.should == @bogus_path
              done
            end
          end
        end
      end
    end
  end
end



