require 'spec_helper'

describe Travis::Services::FindJob do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, repository: repo, state: :created, queue: 'builds.linux') }
  let(:params)  { { id: job.id } }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds the job with the given id' do
      @params = { id: job.id }
      expect(service.run).to eq(job)
    end

    it 'does not raise if the job could not be found' do
      @params = { id: job.id + 1 }
      expect { service.run }.not_to raise_error
    end

    it 'raises RecordNotFound if a SubclassNotFound error is raised during find' do
      find_by_id = stub
      find_by_id.stubs(:find_by_id).raises(ActiveRecord::SubclassNotFound)
      service.stubs(:scope).returns(find_by_id)
      expect { service.run }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'updated_at' do
    it 'returns jobs updated_at attribute' do
      expect(service.updated_at.to_s).to eq(job.updated_at.to_s)
    end
  end

  # TODO jobs can be requeued, so finished jobs are no more final
  #
  # describe 'final?' do
  #   it 'returns true if the job is finished' do
  #     job.update_attributes!(state: :errored)
  #     service.final?.should be_true
  #   end

  #   it 'returns false if the job is not finished' do
  #     job.update_attributes!(state: :started)
  #     service.final?.should be_false
  #   end
  # end
end
