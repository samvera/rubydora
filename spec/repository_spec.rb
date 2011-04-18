require 'spec_helper'

describe Rubydora::Repository do
  before(:each) do
    @repository = Rubydora::Repository.new
  end

  describe "client" do
    it "should return a RestClient resource" do
      client = @repository.client :url => 'http://example.org', :user => 'fedoraAdmin', :password => 'fedoraAdmin'

      client.should be_a_kind_of(RestClient::Resource)
    end
  end

  describe "find" do

  it "should load objects by pid" do
    @mock_object = mock(Rubydora::DigitalObject)
    Rubydora::DigitalObject.should_receive(:find).with("pid", instance_of(Rubydora::Repository)).and_return @mock_object

    @repository.find('pid')
  end

  end

  describe "sparql" do
  it "should return csv results for sparql queries" do
    resource_index_query = ""
    @repository.should_receive(:risearch).with(resource_index_query).and_return("pid\na\nb\nc\n")

    csv = @repository.sparql(resource_index_query)
  end

  describe "profile" do
    it "should map the fedora repository description to a hash" do
      @mock_response = mock()
      @mock_client = mock(RestClient::Resource)
      @mock_response.should_receive(:get).and_return <<-XML
        <?xml version="1.0" encoding="UTF-8"?><fedoraRepository  xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.fedora.info/definitions/1/0/access/ http://www.fedora.info/definitions/1/0/fedoraRepository.xsd"><repositoryName>Fedora Repository</repositoryName><repositoryBaseURL>http://localhost:8983/fedora</repositoryBaseURL><repositoryVersion>3.3</repositoryVersion><repositoryPID>    <PID-namespaceIdentifier>changeme</PID-namespaceIdentifier>    <PID-delimiter>:</PID-delimiter>    <PID-sample>changeme:100</PID-sample>    <retainPID>*</retainPID></repositoryPID><repositoryOAI-identifier>    <OAI-namespaceIdentifier>example.org</OAI-namespaceIdentifier>    <OAI-delimiter>:</OAI-delimiter>    <OAI-sample>oai:example.org:changeme:100</OAI-sample></repositoryOAI-identifier><sampleSearch-URL>http://localhost:8983/fedora/search</sampleSearch-URL><sampleAccess-URL>http://localhost:8983/fedora/get/demo:5</sampleAccess-URL><sampleOAI-URL>http://localhost:8983/fedora/oai?verb=Identify</sampleOAI-URL><adminEmail>bob@example.org</adminEmail><adminEmail>sally@example.org</adminEmail></fedoraRepository>
      XML
      @mock_client.should_receive(:[]).with('describe?xml=true').and_return(@mock_response)
      @repository.should_receive(:client).and_return(@mock_client)
      profile = @repository.profile
      profile['repositoryVersion'].should == '3.3'
    end
  end

  describe "ping" do
    it "should raise an error if a connection cannot be established" do
      @repository.should_receive(:profile).and_return nil
      lambda { @repository.ping }.should raise_error
    end
  end


end

  describe "load_api_abstraction" do
    class ApiAbstractionTestClass < Rubydora::Repository 
      def version; 3.3; end
    end
    it "should load an abstraction layer for relationships for older versions of the fedora rest api" do
      @mock_repository = ApiAbstractionTestClass.new
      @mock_repository.should be_a_kind_of(Rubydora::RestApiClient::V33)
    end
  end

describe "find_by_sparql" do
  it "should attempt to load objects from the results of a sparql query" do

    resource_index_query = ""
    @repository.should_receive(:risearch).with(resource_index_query).and_return("pid\na\nb\nc\n")

    @repository.should_receive(:find).with('a').and_return(1)
    @repository.should_receive(:find).with('b').and_return(1)
    @repository.should_receive(:find).with('c').and_return(1)

    objects = @repository.find_by_sparql(resource_index_query)

    objects.length.should == 3
  end
  end

end
