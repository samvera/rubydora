require 'spec_helper'

describe Rubydora::ResourceIndex do
  class MockRepository
    include Rubydora::ResourceIndex
  end

  before(:each) do
    @mock_repository = MockRepository.new
  end

  it "should map a simple relationship query into SPARQL" do
    @mock_repository.should_receive(:find_by_sparql) do |query|
      query.should match(/\<pid\> \<predicate\> \?pid/)
    end

    @mock_repository.find_by_sparql_relationship('pid', 'predicate')
  end

  it "should send sparql queries with appropriate parameters" do
    @mock_risearch = mock()
    @mock_client = mock(RestClient::Resource)
    @mock_risearch.should_receive(:post).with(hash_including(:dt => 'on', :format => 'CSV', :lang => 'sparql', :limit => nil, :query => 'placeholder SPARQL query', :type => 'tuples' ))
    @mock_client.should_receive(:[]).with('risearch').and_return(@mock_risearch)
    @mock_repository.should_receive(:client).and_return(@mock_client)
    @mock_repository.risearch 'placeholder SPARQL query'
  end
end
