require 'spec_helper'

describe Travis::Services::RegenerateRepoKey do
  include Support::ActiveRecord

  let(:user)    { User.first || Factory(:user) }
  let!(:repo)   { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:service) { described_class.new(user, :id => repo.id) }

  before :each do
    service.expects(:service).with(:find_repo, :id => repo.id).returns(stub(:run => repo))
    user.permissions.create!(:repository_id => repo.id, :admin => true)
  end

  describe 'given the request is authorized' do
    it 'regenerates the key' do
      repo.expects(:regenerate_key!)
      expect(service.run).to eq(repo.reload.key)
    end
  end

  describe 'given the request is not authorized' do
    it 'does not regenerate key' do
      user.permissions.destroy_all
      repo.expects(:regenerate_key!).never
      expect(service.run).to be_falsey
    end
  end
end
