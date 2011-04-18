require 'spec_helper'


# These tests require a fedora repository with the resource index enabled (and with syncUpdates = true)
describe "Integration testing against a live Fedora repository" do
  REPOSITORY_CONFIG = { :url => 'http://localhost:8080/fedora', :user => 'fedoraAdmin', :password => 'fedoraAdmin' }
  before(:all) do
    @repository = Rubydora.connect REPOSITORY_CONFIG
  end

  it "should connect" do
    @repository.ping.should == true
  end

  it "should create an object" do
    obj = @repository.find('test:1')
    obj.new?.should == true
    obj = obj.save
    obj.new?.should == false
  end

  it "should have default datastreams" do
    obj = @repository.find('test:1')
    obj.datastreams.keys.should include("DC")
  end

  it "should list object models" do
    obj = @repository.find('test:1')
    obj.models.should include("info:fedora/fedora-system:FedoraObject-3.0")
  end

  it "should create another object" do
    obj = @repository.find('test:2')
    obj.save
    obj.new?.should == false
  end

  it "should create parts" do
    obj = @repository.find('test:1')
    obj2 = @repository.find('test:2')
    obj.parts << obj2
  end

  it "should persist parts" do
    obj = @repository.find('test:1')
  end

  it "should have a RELS-EXT datastream" do
    obj = @repository.find('test:1')
    obj.datastreams.keys.should include("RELS-EXT")
  end

  it "should create a managed datastream" do
    obj = @repository.find('test:1')
    obj = obj.save
    ds = obj.datastreams["Test"]

    ds.content = open(__FILE__).read
    ds.mimeType = 'text/plain'
    ds.save
  end

  it "should create a redirect datastream" do
    obj = @repository.find('test:1')
    ds = obj.datastreams["Redirect"]
    ds.controlGroup = "R"
    ds.dsLocation = "http://example.org"
    ds.save
  end

  it "should have datastreams" do
    obj = @repository.find('test:1')
    obj.datastreams.keys.should include("Test")
    obj.datastreams.keys.should include("Redirect")
  end

  it "should have datastream content" do
    obj = @repository.find('test:1')
    obj.datastreams["Test"].content.should match( "Integration testing against a live Fedora repository")
  end

  it "should delete datastreams" do
    obj = @repository.find('test:1')
    ds = obj.datastreams["Test"].delete
    obj.datastreams.keys.should_not include("Test")
  end


  after(:all) do
    @repository.find('test:1').delete rescue nil
    @repository.find('test:2').delete rescue nil
  end
end
