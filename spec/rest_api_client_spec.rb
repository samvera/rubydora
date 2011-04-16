require 'spec_helper' 

describe Rubydora::RestApiClient do
  class MockRepository
    include Rubydora::RestApiClient

    attr_accessor :config
  end

  before(:each) do
    @mock_repository = MockRepository.new
    @mock_repository.config = { :url => 'http://example.org',:user => 'fedoraAdmin', :password => 'fedoraAdmin'}
  end

  it "should call nextPID" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/nextPID?format=xml"))
    @mock_repository.next_pid
  end

  it "should find objects" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects?query=a&format=xml"))
    @mock_repository.find_objects :query => 'a'
  end

  it "should show object properties" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/z?format=xml"))
    @mock_repository.object :pid => 'z'
  end
  
  it "ingest" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/new?format=xml"))
    @mock_repository.ingest
  end

  it "ingest with pid" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid?format=xml"))
    @mock_repository.ingest :pid => 'mypid'
  end

  it "modify_object" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid?format=xml&state=Z"))
    @mock_repository.modify_object :pid => 'mypid', :state => 'Z'
  end

  it "purge_object" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid?format=xml"))
    @mock_repository.purge_object :pid => 'mypid'
  end

  it "object_versions" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/versions?format=xml"))
    @mock_repository.object_versions :pid => 'mypid'
  end

  it "object_xml" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/objectXML?format=xml"))
    @mock_repository.object_xml :pid => 'mypid'
  end

  it "datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams?format=xml"))
    @mock_repository.datastream :pid => 'mypid'
  end

  it "datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa?format=xml"))
    @mock_repository.datastream :pid => 'mypid', :dsid => 'aaa'
  end

  it "datastream_dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa/content"))
    @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa'
  end

  it "add_datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa?format=xml"))
    @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa' 
  end

  it "modify_datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa?format=xml"))
    @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa' 
  end

  it "purge_datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa?format=xml"))
    @mock_repository.purge_datastream :pid => 'mypid', :dsid => 'aaa' 
  end

  it "set_datastream_options" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa?format=xml&aparam=true"))
    @mock_repository.set_datastream_options :pid => 'mypid', :dsid => 'aaa', :aparam => true 
  end

  it "datastream_versions" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa/versions?format=xml"))
    @mock_repository.datastream_versions :pid => 'mypid', :dsid => 'aaa'

  end

  it "relationships" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/relationships?format=xml"))
    @mock_repository.relationships :pid => 'mypid'
  end

  it "add_relationship" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/relationships?subject=z&format=xml"))
    @mock_repository.add_relationship :pid => 'mypid', :subject => 'z'
  end

  it "purge_relationships" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/relationships?subject=z&format=xml"))
    @mock_repository.purge_relationship :pid => 'mypid', :subject => 'z' 
  end

  it "dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/methods?format=xml"))
    @mock_repository.dissemination :pid => 'mypid'
  end

  it "dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/methods/sdef?format=xml"))
    @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef'
  end

  it "dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/methods/sdef/method?format=xml"))
    @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef', :method => 'method'
  end

end
