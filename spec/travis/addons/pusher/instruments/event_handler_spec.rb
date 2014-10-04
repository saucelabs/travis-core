require 'spec_helper'

describe Travis::Addons::Pusher::Instruments::EventHandler do
  include Travis::Testing::Stubs

  let(:subject)   { Travis::Addons::Pusher::EventHandler }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events[1] }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    subject.any_instance.stubs(:handle)
  end

  describe 'given a job:started event' do
    it 'publishes a event' do
      subject.notify('job:test:started', test)

      expect(event).to publish_instrumentation_event(
        event: 'travis.addons.pusher.event_handler.notify:completed',
        message: 'Travis::Addons::Pusher::EventHandler#notify:completed (job:test:started) for #<Test id=1>',
      )
      expect(event[:data].except(:payload)).to eq({
        repository: 'svenfuchs/minimal',
        request_id: 1,
        object_id: 1,
        object_type: 'Test',
        event: 'job:test:started',
      })
      expect(event[:data][:payload]).not_to be_nil
    end
  end

  describe 'given a build:finished event' do
    it 'publishes a event' do
      subject.notify('build:finished', build)

      expect(event).to publish_instrumentation_event(
        event: 'travis.addons.pusher.event_handler.notify:completed',
        message: 'Travis::Addons::Pusher::EventHandler#notify:completed (build:finished) for #<Build id=1>',
      )
      expect(event[:data].except(:payload)).to eq({
        repository: 'svenfuchs/minimal',
        request_id: 1,
        object_id: 1,
        object_type: 'Build',
        event: 'build:finished',
      })
      expect(event[:data][:payload]).not_to be_nil
    end
  end
end

