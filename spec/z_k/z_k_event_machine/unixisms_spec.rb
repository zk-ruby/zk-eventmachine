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

    describe 'mkdir_p' do

      it %[should create the path recursively] do
        em do
          @zkem.connect do
            
            done

          end
        end
      end
    end
  end
end



