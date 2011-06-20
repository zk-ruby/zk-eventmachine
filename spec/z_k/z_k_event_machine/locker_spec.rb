require 'spec_helper'

module ZK::ZKEventMachine
  include EventedSpec::SpecHelper
  default_timeout 3.0

  before do
    @zk = ::ZK.new
    @base_path = '/zk-em-testing'
    @zk.rm_rf(@base_path)
    @zk.mkdir_p(@base_path)
    @zkem = ZK::ZKEventMachine.new('localhost:2181')
  end

  after do
    @zk.rm_rf(@base_path)
    @zk.close!
    @zkem.close!
  end


  describe 'Locker' do

    describe 'lock' do
      it %[should acquire a lock on the node and then call the callback] 

      it %[should be compatible with the synchronous version] 

      it %[should release the lock if an exception occurs]

    end
  end
end

