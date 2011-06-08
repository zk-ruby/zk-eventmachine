require 'spec_helper'

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

          it %[should have the correct number of args] do
            @callback_args.length.should == 2
          end

          it %[should have the correct args] do
            @callback_args[0].should == 'data'
            @callback_args[1].should == @stat_mock
          end
        end

        describe 'failure' do
          before do
            @cb.call(:rc => ::ZK::Exceptions::NONODE)
          end

          it %[should have called the errback] do
            @errback_args.should_not be_nil
          end

          it %[should be called with the appropriate exception instance] do
            @errback_args.first.should be_instance_of(::ZK::Exceptions::NoNode)
          end
        end
      end

      describe 'with an on_result block set' do
        before do
          @args = nil

          @cb.on_result do |*a|
            @args = a
          end
        end

        describe 'success' do
          before do
            @cb.call(:rc => 0, :data => 'data', :stat => @stat_mock, :context => @context_mock)
          end

          it %[should have called the block] do
            @args.should_not be_nil
          end

          it %[should have used the correct arguments] do
            @args[0].should == nil
            @args[1].should == 'data'
            @args[2].should == @stat_mock
          end
        end

        describe 'failure' do
          before do
            @cb.call(:rc => ::ZK::Exceptions::NONODE)
          end

          it %[should have called the block] do
            @args.should_not be_nil
          end

          it %[should have used the correct arguments] do
            @args.first.should be_instance_of(::ZK::Exceptions::NoNode)
          end
        end
      end

      describe 'on_result can be handed a block' do
        before do
          @args = nil

          blk = lambda { |*a| @args = a }

          @cb.on_result(blk)
        end

        describe 'success' do
          before do
            @cb.call(:rc => 0, :data => 'data', :stat => @stat_mock, :context => @context_mock)
          end

          it %[should have called the block] do
            @args.should_not be_nil
          end

          it %[should have used the correct arguments] do
            @args[0].should == nil
            @args[1].should == 'data'
            @args[2].should == @stat_mock
          end
        end
      end
    end
  end
end

