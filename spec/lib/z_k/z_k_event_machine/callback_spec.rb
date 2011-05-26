require File.expand_path('../../../../spec_helper', __FILE__)

describe 'ZK::ZKEventMachine::Callback' do
  before do
    @stat_mock = flexmock(:stat)
    @context_mock = flexmock(:context)

    flexmock(::EM) do |em|
      em.should_receive(:next_tick).with(Proc).and_return { |b| b.call }
    end

  end

  describe 'DataCallback' do
    before do
      @cb = ZK::ZKEventMachine::Callback::DataCallback.new
    end

    describe 'call' do
      describe 'with callbacks and errbacks set' do
        before do
          @callback_args = @errback_args = nil

          @cb.callback do |*a|
            @callback_args = a
          end

          @cb.errback do |*a|
            @errback_args = a
          end
        end

        describe 'success' do
          before do
            @cb.call(:rc => 0, :data => 'data', :stat => @stat_mock, :context => @context_mock)
          end

          it %[should have called the callback] do
            @callback_args.should_not be_nil
          end

          it %[should have] do
          end
        end
      end
    end
  end
end

