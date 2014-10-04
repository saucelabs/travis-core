require 'spec_helper'

describe Travis::Services::FindRepoKey do
  include Support::ActiveRecord

  let!(:repo)   { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds a key by the given repository id' do
      @params = { :id => repo.id }
      expect(service.run).to eq(repo.key)
    end

    it 'finds a key by the given owner_name and name' do
      @params = { :owner_name => repo.owner_name, :name => repo.name }
      expect(service.run).to eq(repo.key)
    end
  end

  describe 'updated_at' do
    it 'returns key\'s updated_at attribute' do
      @params = { :id => repo.id }
      expect(service.updated_at.to_s).to eq(repo.key.updated_at.to_s)
    end
  end
end
