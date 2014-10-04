require 'spec_helper'

describe Travis::Github::Services::FetchConfig do
  include Travis::Testing::Stubs, Support::Redis

  let(:body)      { { 'content' => ['foo: Foo'].pack('m') } }
  let(:service)   { described_class.new(nil, request: request) }
  let(:result)    { service.run }
  let(:exception) { GH::Error.new }

  before :each do
    GH.stubs(:[]).with(request.config_url).returns(body)
  end

  describe 'config' do
    it 'returns a hash' do
      expect(result).to be_a(Hash)
    end

    it 'yaml parses the response body if the response is successful' do
      expect(result['foo']).to eq('Foo')
    end

    it "merges { '.result' => 'configured' } to the actual configuration" do
      expect(result['.result']).to eq('configured')
    end

    it "returns { '.result' => 'not_found' } if a 404 is returned" do
      exception.stubs(info: { response_status: 404 })
      GH.stubs(:[]).raises(exception)
      expect(result['.result']).to eq('not_found')
    end

    it "returns { '.result' => 'server_error' } if a 500 is returned" do
      exception.stubs(info: { response_status: 500 })
      GH.stubs(:[]).raises(exception)
      expect(result['.result']).to eq('server_error')
    end

    it "returns { '.result' => 'parse_error' } if the .travis.yml is invalid" do
      GH.stubs(:[]).returns({ "content" => ["\tfoo: Foo"].pack("m") })
      expect(result['.result']).to eq('parse_error')
    end

    it "returns the error message for an invalid .travis.yml file" do
      GH.stubs(:[]).returns({ "content" => ["\tfoo: Foo"].pack("m") })
      expect(result[".result_message"]).to match(/line 1 column 1/)
    end

    it "converts non-breaking spaces to normal spaces" do
      GH.stubs(:[]).returns({ "content" => ["foo:\n\xC2\xA0\xC2\xA0bar: Foobar"].pack("m") })
      expect(result["foo"]).to eql({ "bar" => "Foobar" })
    end

    context "when the repository has the osx_alt_image feature enabled" do
      before do
        Travis::Features.activate_repository(:osx_alt_image, request.repository)
      end

      it "passes the 'osx_image' config key through" do
        GH.stubs(:[]).returns({ "content" => ["osx_image: latest"].pack("m") })
        expect(result["osx_image"]).to eql("latest")
      end
    end

    context "when the repository doesn't have the osx_alt_image feature enabled" do
      it "doesn't pass the 'osx_image' config key through" do
        GH.stubs(:[]).returns({ "content" => ["osx_image: latest"].pack("m") })
        expect(result.has_key?("osx_image")).to be false
      end
    end

    context "when the repository has the template_selection feature enabled" do
      before do
        Travis::Features.activate_repository(:template_selection, request.repository)
      end

      it "passes the 'group' config key through" do
        GH.stubs(:[]).returns({ "content" => ["group: latest"].pack("m") })
        expect(result["group"]).to eql("latest")
      end

      it "passes the 'dist' config key through" do
        GH.stubs(:[]).returns({ "content" => ["dist: latest"].pack("m") })
        expect(result["dist"]).to eql("latest")
      end
    end

    context "when the repository doesn't have the template_selection feature enabled" do
      it "doesn't pass the 'group' config key through" do
        GH.stubs(:[]).returns({ "content" => ["group: latest"].pack("m") })
        expect(result.has_key?("group")).to be false
      end

      it "doesn't pass the 'dist' config key through" do
        GH.stubs(:[]).returns({ "content" => ["dist: latest"].pack("m") })
        expect(result.has_key?("dist")).to be false
      end
    end
  end
end

describe Travis::Github::Services::FetchConfig::Instrument do
  include Travis::Testing::Stubs

  let(:body)      { { 'content' => ['foo: Foo'].pack('m') } }
  let(:service)   { Travis::Github::Services::FetchConfig.new(nil, request: request) }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events[1] }

  before :each do
    GH.stubs(:[]).returns(body)
    Travis::Notification.publishers.replace([publisher])
  end

  it 'publishes a payload' do
    service.run
    expect(event).to publish_instrumentation_event(
      event: 'travis.github.services.fetch_config.run:completed',
      message: 'Travis::Github::Services::FetchConfig#run:completed https://api.github.com/repos/svenfuchs/minimal/contents/.travis.yml?ref=62aae5f70ceee39123ef',
      result: { 'foo' => 'Foo', '.result' => 'configured' },
      data: {
        url: 'https://api.github.com/repos/svenfuchs/minimal/contents/.travis.yml?ref=62aae5f70ceee39123ef'
      }
    )
  end

  it 'strips an access_token if present (1)' do
    service.stubs(:config_url).returns('/foo/bar?access_token=123456')
    service.run
    expect(event[:data][:url]).to eq('/foo/bar?access_token=[secure]')
  end

  it 'strips an access_token if present (2)' do
    service.stubs(:config_url).returns('/foo/bar?ref=abcd&access_token=123456')
    service.run
    expect(event[:data][:url]).to eq('/foo/bar?ref=abcd&access_token=[secure]')
  end
end
