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
