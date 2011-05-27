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
      @zkem = ZK::ZKEventMachine::Client.new(@zk)
    end

    after do
      @zk.rm_rf(@base_path)
      @zk.close
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
          dfr = @zkem.get(@path)

          dfr.callback { |*a| @cb_args = a }
          dfr.errback  { |exc| @exc = exc  }

          done
        end

        @cb_args.should_not be_nil
        @cb_args.first.should == @data
        @cb_args.last.should be_instance_of(ZookeeperStat::Stat)
      end
    end
  end
end


