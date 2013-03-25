require 'spec_helper'

describe "#audit_trail" do

  before(:all) do
    path = File.join(File.dirname(__FILE__), 'fixtures', 'audit_trail.foxml.xml')
    # Create Rubydora::DigitalObject
  end
  after(:all) do
    @test_object.delete
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
