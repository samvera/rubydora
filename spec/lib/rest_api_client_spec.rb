require 'spec_helper' 
require 'loggable'

describe Rubydora::RestApiClient do
  class MockRepository
    include Rubydora::RestApiClient
    include Loggable


    attr_accessor :config
  end

  before(:each) do
    @fedora_user = 'fedoraAdmin'
    @fedora_password = 'fedoraAdmin'
    @mock_repository = MockRepository.new
    @mock_repository.config = { :url => 'http://example.org',:user => @fedora_user, :password => @fedora_password}
  end

  it "should create a REST client" do
    client = @mock_repository.client
    
    client.should be_a_kind_of(RestClient::Resource)
    client.options[:user].should == @fedora_user
  end
  
  it "should create a REST client with a client certificate" do
    client = @mock_repository.client :ssl_client_cert => OpenSSL::X509::Certificate.new, :ssl_client_key => OpenSSL::PKey::RSA.new

    client.options[:user].should == @fedora_user
    client.options[:ssl_client_cert].should be_a_kind_of(OpenSSL::X509::Certificate)
    client.options[:ssl_client_key].should be_a_kind_of(OpenSSL::PKey::PKey)
  end

  it "should raise an exception if client is called twice with different options" do
    client = @mock_repository.client
    lambda { client.should == @mock_repository.client }.should_not raise_error
    lambda { @mock_repository.client(:timeout => 120) }.should raise_error(ArgumentError)
  end
  
  it "should call nextPID" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/nextPID?format=xml"))
    @mock_repository.next_pid
  end

  it "should find objects" do
     RestClient::Request.should_receive(:execute) do |params|
       params.should have_key(:url)
       params[:url].should =~ /^#{Regexp.escape("http://example.org/objects?")}.*query=a/
     end
    @mock_repository.find_objects :query => 'a'
  end


  it "should show object properties" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/z?format=xml"))
    @mock_repository.object :pid => 'z'
  end

  it "should raise not found exception when retrieving object" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/z?format=xml")).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.object(:pid => 'z')}.should raise_error RestClient::ResourceNotFound
  end
  
  it "ingest" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/new"))
    @mock_repository.ingest
  end

  it "ingest with pid" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid"))
    @mock_repository.ingest :pid => 'mypid'
  end

  it "modify_object" do
     RestClient::Request.should_receive(:execute) do |params|
       params.should have_key(:url)
       params[:url].should =~ /^#{Regexp.escape("http://example.org/objects/mypid?")}.*state=Z/
     end
    @mock_repository.modify_object :pid => 'mypid', :state => 'Z'
  end

  it "purge_object" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid"))
    @mock_repository.purge_object :pid => 'mypid'
  end

  it "should raise not found exception when purging" do
    RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid")).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.purge_object(:pid => 'mypid')}.should raise_error RestClient::ResourceNotFound
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

  it "should raise not found exception when getting a datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa?format=xml")).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.datastream :pid => 'mypid', :dsid => 'aaa'}.should raise_error RestClient::ResourceNotFound
  end

  it "datastream_dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa/content"))
    @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa'
  end
  it "should allow http methods besides GET on datastream_dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:method => :head))
    @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa', :method => :head
  end
  it "should pass a block to the rest client to process the response in datastream_dissemination" do
     _proc = lambda { |x| x }
     RestClient::Request.should_receive(:execute).with(hash_including(:block_response => _proc))
    @mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa', &_proc
  end
  it "should raise not found exception when retrieving datastream_dissemination" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa/content")).and_raise( RestClient::ResourceNotFound)
    lambda {@mock_repository.datastream_dissemination :pid => 'mypid', :dsid => 'aaa'}.should raise_error RestClient::ResourceNotFound
  end

  it "add_datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa"))
    @mock_repository.add_datastream :pid => 'mypid', :dsid => 'aaa' 
  end

  describe "modify datastream" do
    it "should not set mime-type when it's not provided" do
       RestClient::Request.should_receive(:execute).with(:url => "http://example.org/objects/mypid/datastreams/aaa",:open_timeout=>nil, :payload=>nil, :user=>@fedora_user, :password=>@fedora_password, :method=>:put, :headers=>{})
      @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa' 
    end
    it "should pass the provided mimeType header" do
       RestClient::Request.should_receive(:execute).with(:url => "http://example.org/objects/mypid/datastreams/aaa?mimeType=application%2Fjson",:open_timeout=>nil, :payload=>nil, :user=>@fedora_user, :password=>@fedora_password, :method=>:put, :headers=>{})
      @mock_repository.modify_datastream :pid => 'mypid', :dsid => 'aaa', :mimeType=>'application/json'
    end
  end

  it "purge_datastream" do
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/datastreams/aaa"))
    @mock_repository.purge_datastream :pid => 'mypid', :dsid => 'aaa' 
  end

  it "set_datastream_options" do
     RestClient::Request.should_receive(:execute) do |params|
       params.should have_key(:url)
       params[:url].should =~ /^#{Regexp.escape("http://example.org/objects/mypid/datastreams/aaa?")}.*aparam=true/ 
     end
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
     RestClient::Request.should_receive(:execute) do |params|
       params.should have_key(:url)
       params[:url].should =~ /^#{Regexp.escape("http://example.org/objects/mypid/relationships/new?")}.*subject=z/
     end
    @mock_repository.add_relationship :pid => 'mypid', :subject => 'z'
  end

  it "purge_relationships" do
     RestClient::Request.should_receive(:execute) do |params|
       params.should have_key(:url)
       params[:url].should =~ /^#{Regexp.escape("http://example.org/objects/mypid/relationships?")}.*subject=z/
     end
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
     RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://example.org/objects/mypid/methods/sdef/method"))
    @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef', :method => 'method'
  end

  it "should pass a block to the rest client to process the response in datastream_dissemination" do
     _proc = lambda { |x| x }
     RestClient::Request.should_receive(:execute).with(hash_including(:block_response => _proc))
     @mock_repository.dissemination :pid => 'mypid', :sdef => 'sdef', :method => 'method', &_proc
  end

end
