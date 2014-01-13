require 'spec_helper'

describe "#audit_trail" do

  before do
    path = File.join(File.dirname(__FILE__), 'fixtures', 'audit_trail.foxml.xml')
    File.open(path, 'rb') do |f|
      @xml = f.read
    end
    @repo = Rubydora::Repository.new
    @repo.api.stub(:object_xml).with(hash_including(:pid => 'foo:bar')).and_return(@xml)
    @test_object = Rubydora::DigitalObject.new('foo:bar', @repo)
  end
  it "should have the correct number of audit records" do
    @test_object.audit_trail.records.length.should == 3
  end
  it "should return all the data from each audit record" do
    record = @test_object.audit_trail.records.first
    record.id.should == "AUDREC1"
    record.process_type.should == "Fedora API-M"
    record.action.should == "addDatastream"
    record.component_id.should == "RELS-EXT"
    record.responsibility.should == "fedoraAdmin"
    record.date.should == "2013-02-25T16:43:06.219Z"
    record.justification.should == ""
  end
  
end
