require 'spec_helper'

describe Rubydora::DigitalObject do
  describe "find" do
    it "should load a DigitalObject instance" do
      Rubydora::DigitalObject.find("pid").should be_a_kind_of(Rubydora::DigitalObject::Base)
    end
  end

  describe "profile" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.find 'pid', @mock_repository
    end

    it "should convert object profile to a simple hash" do
      @mock_repository.should_receive(:object).with(:pid => 'pid').and_return("<objectProfile><a>1</a><b>2</b><objModels><model>3</model><model>4</model></objectProfile>")
      h = @object.profile

      h.should have_key("a")
      h['a'].should == '1'
      h.should have_key("b")
      h['b'].should == '2'
      h.should have_key("objModels")
      h['objModels'].should == ['3', '4']

    end
  end

  describe "create" do
    it "should call the Fedora REST API to create a new object" do
      @mock_repository = mock(Rubydora::Repository)
      @mock_repository.should_receive(:ingest).with(instance_of(Hash)).and_return(nil)
      obj = Rubydora::DigitalObject.create "pid", { :a => 1, :b => 2}, @mock_repository
      obj.should be_a_kind_of(Rubydora::DigitalObject::Base)
    end
  end

  describe "retreive" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.find 'pid', @mock_repository
    end

    describe "datastreams" do
      it "should provide a hash populated by the existing datastreams" do
        @mock_repository.should_receive(:datastreams).with(:pid => 'pid').and_return("<objectDatastreams><datastream dsid='a'></datastream>><datastream dsid='b'></datastream>><datastream dsid='c'></datastream></objectDatastreams>")

        @object.datastreams.should have_key("a")
        @object.datastreams.should have_key("b")
        @object.datastreams.should have_key("c")
      end

      it "should allow other datastreams to be added" do
        @mock_repository.should_receive(:datastreams).with(:pid => 'pid').and_return("<objectDatastreams><datastream dsid='a'></datastream>><datastream dsid='b'></datastream>><datastream dsid='c'></datastream></objectDatastreams>")

        @object.datastreams.length.should == 3

        ds = @object.datastreams["z"]
        ds.should be_a_kind_of(Rubydora::Datastream::Base)
        ds.new?.should == true

        @object.datastreams.length.should == 4
      end
      
    end

  end

  describe "save" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.find 'pid', @mock_repository
    end

    it "should save all dirty datastreams" do
      @ds1 = mock()
      @ds1.should_receive(:dirty?).and_return(false)
      @ds1.should_not_receive(:save)
      @ds2 = mock()
      @ds2.should_receive(:dirty?).and_return(true)
      @ds2.should_receive(:empty?).and_return(true)
      @ds2.should_not_receive(:save)
      @ds3 = mock()
      @ds3.should_receive(:dirty?).and_return(true)
      @ds3.should_receive(:empty?).and_return(false)
      @ds3.should_receive(:save)

      @object.should_receive(:datastreams).and_return([@ds1, @ds2, @ds3])

      @object.save
    end
  end

  describe "delete" do
    before(:each) do
      @mock_repository = mock()
      @object = Rubydora::DigitalObject.find 'pid', @mock_repository
    end

    it "should call the Fedora REST API" do
      @mock_repository.should_receive(:purge_object).with({:pid => 'pid'})
      @object.delete
    end
  end

end
