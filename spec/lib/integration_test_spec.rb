require 'spec_helper'


# These tests require a fedora repository with the resource index enabled (and with syncUpdates = true)
describe "Integration testing against a live Fedora repository", :integration => true do
  REPOSITORY_CONFIG = { :url => 'http://localhost:8983/fedora', :user => 'fedoraAdmin', :password => 'fedoraAdmin' }
  before(:all) do
    @repository = Rubydora.connect REPOSITORY_CONFIG
    @repository.find('test:1').delete rescue nil
    @repository.find('test:2').delete rescue nil
    @repository.find('test:3').delete rescue nil
  end

  it "should connect" do
    @repository.ping.should == true
  end

  it "should create an object" do
    obj = @repository.find('test:1')
    obj.new?.should == true
    obj.save
    obj.new?.should == false
  end

  it "new should not return true until the profile is read" do
    obj = @repository.find('test:1')
    obj.save
    new_obj = Rubydora::DigitalObject.new('test:1', @repository)
    new_obj.new?.should == false 
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

  it "should create and update object labels" do
    obj = @repository.find('test:3')
    obj.label = 'asdf'
    obj.save

    obj = @repository.find('test:3')
    obj.label.should == 'asdf'
    obj.label = 'qwerty'
    obj.save

    obj = @repository.find('test:3')
    obj.label.should == 'qwerty'

  end

  it "should persist parts" do
    obj = @repository.find('test:1')
  end

  it "should create a managed datastream" do
    obj = @repository.find('test:1')
    obj.save
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

  it "should have profile attributes" do
    obj = @repository.find('test:1')
    ds = obj.datastreams["Test"]

    ds.versionID.should == "Test.0"

    (Time.now - ds.createDate).should be < 60*60 # 1 hour
    ds.state.should == "A"
    ds.controlGroup.should == "M"
    ds.size.should be > 100
  end

  it "should delete datastreams" do
    obj = @repository.find('test:1')
    ds = obj.datastreams["Test"].delete
    obj.datastreams.keys.should_not include("Test")
  end

  it "should save changed datastreams when the object is saved" do
    obj = @repository.find('test:1')
    obj.datastreams["new_ds"].content = "XXX"
    obj.datastreams["empty_ds"].new?
    obj.save

    obj.datastreams["new_ds"].new?.should == false
    obj.datastreams["empty_ds"].new?.should == true
  end

  it "should update datastream attributes without changing the content (or mime type)" do
    obj = @repository.find('test:1')
    obj.datastreams["my_ds"].content = "XXX"
    obj.datastreams["my_ds"].mimeType = "application/x-text"
    obj.save

    obj = @repository.find('test:1')
    obj.datastreams["my_ds"].dsLabel = "New Label"
    obj.save

    obj = @repository.find('test:1')
    obj.datastreams["my_ds"].content.should == "XXX"
    obj.datastreams["my_ds"].dsLabel.should == "New Label"
    obj.datastreams["my_ds"].mimeType.should == "application/x-text"
  end


  describe "object versions" do
    it "should have versions" do
      obj = @repository.find('test:1')
      obj.versions.should_not be_empty
    end

    it "should have read-only versions" do
      obj = @repository.find('test:1')
      expect { obj.versions.first.label = "asdf" }.to raise_error
    end

    ## This isn't how Fedora object profiles actually work??
    #it "should access profile data using asOfDateTime" do
    #  obj = @repository.find('test:3')
    #  obj.label = "asdf"
    #  obj.save
    #
    #  obj = @repository.find('test:3')
    #  obj.label = "qwerty"
    #  obj.save
    #
    #  obj = @repository.find('test:3')
    #  obj.versions.map { |x| x.label }.should include('adsf', 'qwerty')
    #end

    it "should access datastreams list using asOfDateTime (and pass the asOfDateTime through to the datastreams)" do
      obj = @repository.find('test:1')
      oldest = obj.versions.first.datastreams.keys
      newest = obj.versions.last.datastreams.keys
      (newest - oldest).should_not be_empty

      obj.versions.first.datastreams.values.first.asOfDateTime.should == obj.versions.first.asOfDateTime
    end
  end

  describe "datastream versions" do

    it "should have versions" do
      obj = @repository.find('test:1')
      versions = obj.datastreams["my_ds"].versions
      versions.should_not be_empty
      versions.map { |x| x.versionID }.should include('my_ds.1', 'my_ds.0')
    end

    it "should have read-only versions" do
      obj = @repository.find('test:1')
      ds = obj.datastreams["my_ds"].asOfDateTime(Time.now)
      expect { ds.dsLabel = 'asdf' }.to raise_error
      expect { ds.content = 'asdf' }.to raise_error
    end

    it "should access the content of older datastreams" do
      obj = @repository.find('test:1')

      ds = obj.datastreams["my_ds"]
      ds.content = "YYY"
      ds.save

      versions = obj.datastreams["my_ds"].versions
      versions.map { |x| x.content }.should include("XXX", "YYY") 
    end
  end

  context "mime types" do
    before(:each) do
      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].delete rescue nil
    end

    it "should default to application/octet-stream" do
      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content = "XXX"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].mimeType.should == "application/octet-stream"
    end

    it "should allow the user to specify a mimetype" do
      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content = "XXX"
      obj.datastreams["my_ds"].mimeType = "text/plain"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].mimeType.should == "text/plain"
    end

    it "should preserve the mimetype on update" do
      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content = "XXX"
      obj.datastreams["my_ds"].mimeType = "text/plain"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content = "ZZZ"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].mimeType.should == "text/plain"
    end

    it "should allow the mimetype to be changed" do
      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content = "XXX"
      obj.datastreams["my_ds"].mimeType = "text/plain"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].mimeType = "application/json"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].mimeType.should == "application/json"
    end

  end

  describe "search" do

    it "should return an array of fedora objects" do
      objects = @repository.search('')

      objects.map { |x| x.pid }.should include('test:1', 'test:2')
    end

    it "should include our new objects" do
      pids = []
      @repository.search('') { |obj| pids << obj.pid }

      pids.should include('test:1', 'test:2')
    end

  end

  it "should not destroy content when datastream properties are changed" do
      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content = "XXX"
      obj.datastreams["my_ds"].mimeType = "text/plain"
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].mimeType = 'application/json'
      obj.save

      obj = @repository.find('test:1')
      obj.datastreams["my_ds"].content.should == "XXX"
  end


  after(:all) do
    @repository.find('test:1').delete rescue nil
    @repository.find('test:2').delete rescue nil
  end
end
