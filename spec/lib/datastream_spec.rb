require 'spec_helper'

describe Rubydora::Datastream do
  before do
    @mock_repository = mock(Rubydora::Repository)
    @mock_object = mock(Rubydora::DigitalObject)
    @mock_object.stub(:repository => @mock_repository, :pid => 'pid')
  end


  describe "create" do
    before(:each) do
      @mock_repository.stub(:datastream) { raise("") }
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
    end

    it "should be new" do
      @datastream.new?.should == true
    end

    it "should be dirty" do
      @datastream.changed?.should == false
    end

    it "should have default values" do
      @datastream.controlGroup == "M"
      @datastream.dsState.should == "A"
      @datastream.checksumType.should == "DISABLED"
      @datastream.versionable.should == true
      @datastream.changed.should be_empty
    end


    it "should call the appropriate api on save" do
      @mock_repository.should_receive(:add_datastream).with(hash_including(:pid => 'pid', :dsid => 'dsid', :controlGroup => 'M', :dsState => 'A'))
      @datastream.save
    end

    it "should be able to override defaults" do
      @mock_repository.should_receive(:add_datastream).with(hash_including(:controlGroup => 'E'))
      @datastream.controlGroup = 'E'
      @datastream.save
    end
  end

  describe "retrieve" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @mock_repository.should_receive(:datastream).any_number_of_times.and_return <<-XML
        <datastreamProfile>
          <dsLocation>some:uri</dsLocation>
          <dsLabel>label</dsLabel>
        </datastreamProfile>
      XML
    end

    it "should not be new" do
      @datastream.new?.should == false
      @datastream.changed?.should == false
    end

    it "should provide attribute defaults from dsProfile" do
      @datastream.dsLocation.should == 'some:uri'
      @datastream.dsLabel.should == 'label'
    end

    it "should mediate access to datastream contents" do
      @mock_repository.should_receive(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('asdf') 
      @datastream.content.should == "asdf"
    end

    it "should rewind IO-type contents" do
      @mock_io = File.open('rubydora.gemspec')
      @mock_io.should_receive(:rewind)

      @datastream.content = @mock_io

      @datastream.content.should be_a(String)

    end


  end

  describe "update" do

    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @mock_repository.should_receive(:datastream).any_number_of_times.and_return <<-XML
        <datastreamProfile>
          <dsLocation>some:uri</dsLocation>
          <dsLabel>label</dsLabel>
        </datastreamProfile>
      XML
    end

    it "should not say changed if the value is set the same" do
      @datastream.dsLabel = "label"
      @datastream.should_not be_changed
    end

    it "should allow profile attributes to be replaced" do
      @datastream.dsLabel = "New Label"
      @datastream.dsLabel.should == "New Label"
    end

    it "should call the appropriate api with any dirty attributes" do
      @mock_repository.should_receive(:modify_datastream).with(hash_including(:dsLabel => "New Label"))
      @datastream.dsLabel = "New Label"
      @datastream.save
    end

    it "should update the datastream when the content is changed" do
      @mock_repository.should_receive(:modify_datastream).with(hash_including(:content => 'test'))
      @datastream.content = "test"
      @datastream.save
    end

    it "should be marked as changed when the content is updated" do
      @datastream.changed?.should be_false
      @datastream.content = "test"
      @datastream.changed?.should be_true
    end

  end

  describe "should check if an object is read-only" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @mock_repository.should_receive(:datastream).any_number_of_times.and_return <<-XML
        <datastreamProfile>
          <dsLocation>some:uri</dsLocation>
          <dsLabel>label</dsLabel>
        </datastreamProfile>
      XML
    end

    it "before updating attributes" do
      @datastream.should_receive(:check_if_read_only)
      @datastream.dsLabel = 'New Label'
    end

    it "before saving an object" do
      @mock_repository.should_receive(:modify_datastream)
      @datastream.should_receive(:check_if_read_only)
      @datastream.save
    end

    it "before deleting an object" do
      @mock_repository.should_receive(:purge_datastream)
      @mock_object.should_receive(:datastreams).and_return([])
      @datastream.should_receive(:check_if_read_only)
      @datastream.delete
    end
  end

  describe "versions" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @mock_repository.should_receive(:datastream_versions).any_number_of_times.and_return <<-XML
      <datastreamHistory>
        <datastreamProfile>
          <dsVersionID>dsid.1</dsVersionID>
          <dsCreateDate>2010-01-02T00:00:00.012Z</dsCreateDate>
        </datastreamProfile>
        <datastreamProfile>
          <dsVersionID>dsid.0</dsVersionID>
          <dsCreateDate>2008-08-05T01:30:05.012Z</dsCreateDate>
        </datastreamProfile>
      </datastreamHistory>
      XML
    end

    it "should have a list of previous versions" do
      @datastream.versions.should have(2).items
    end

    it "should access versions as read-only copies" do
      expect { @datastream.versions.first.label = "asdf" }.to raise_error
    end

    it "should lookup content of datastream using the asOfDateTime parameter" do
      @mock_repository.should_receive(:datastream_dissemination).with(hash_including(:asOfDateTime => '2008-08-05T01:30:05.012Z'))
      @datastream.versions.last.content
    end
    
  end

  describe "datastream attributes" do
    before do
      @mock_repository.stub(:datastream => <<-XML
        <datastreamProfile>
        <anyProfileValue />
        </datastreamProfile>
      XML
    )
    end

  shared_examples "a datastream attribute" do
    subject { Rubydora::Datastream.new @mock_object, 'dsid' }

    describe "getter" do
      it "should return the value" do
        subject.instance_variable_set("@#{method}", 'asdf')
        subject.send(method).should == 'asdf'
      end

      it "should look in the object profile" do
        subject.should_receive(:profile) { { Rubydora::Datastream::DS_ATTRIBUTES[method.to_sym].to_s => 'qwerty' } }
        subject.send(method).should == 'qwerty'
      end

      it "should fall-back to the set of default attributes" do
        Rubydora::Datastream::DS_DEFAULT_ATTRIBUTES.should_receive(:[]).with(method.to_sym) { 'zxcv'} 
        subject.send(method).should == 'zxcv'
      end
    end

    describe "setter" do
      before do
        subject.stub(:datastreams => [])
      end
      it "should mark the object as changed after setting" do
        subject.send("#{method}=", 'new_value')
        subject.should be_changed
      end

      it "should not mark the object as changed if the value does not change" do
        subject.should_receive(method) { 'zxcv' }
        subject.send("#{method}=", 'zxcv')
      end

      it "should appear in the save request" do 
        @mock_repository.should_receive(:modify_datastream).with(hash_including(method.to_sym => 'new_value'))
        subject.send("#{method}=", 'new_value')
        subject.save
      end
    end
  end

  shared_examples "a read-only datastream attribute" do
    subject { Rubydora::Datastream.new @mock_object, 'dsid' }

    describe "getter" do
      it "should return the value" do
        subject.instance_variable_set("@#{method}", 'asdf')
        subject.send(method).should == 'asdf'
      end

      it "should look in the object profile" do
        subject.should_receive(:profile) { { method => 'qwerty' } }
        subject.send(method).should == 'qwerty'
      end

      it "should fall-back to the set of default attributes" do
        Rubydora::Datastream::DS_DEFAULT_ATTRIBUTES.should_receive(:[]).with(method.to_sym) { 'zxcv'} 
        subject.send(method).should == 'zxcv'
      end
    end

  end

  describe "#controlGroup" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'controlGroup' }
  end

  describe "#dsLocation" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'dsLocation' }
  end

  describe "#altIDs" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'altIDs' }
  end

  describe "#dsLabel" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'dsLabel' }
  end

  describe "#versionable" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'versionable' }
  end

  describe "#dsState" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'dsState' }
  end

  describe "#formatURI" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'formatURI' }
  end

  describe "#checksumType" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'checksumType' }
  end

  describe "#checksum" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'checksum' }
  end

  describe "#mimeType" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'mimeType' }
  end

  describe "#logMessage" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'logMessage' }
  end

  describe "#ignoreContent" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'ignoreContent' }
  end

  describe "#lastModifiedDate" do
    it_behaves_like "a datastream attribute"
    let(:method) { 'lastModifiedDate' }
  end

  describe "#dsCreateDate" do
    it_behaves_like "a read-only datastream attribute"
    let(:method) { 'dsCreateDate' }
  end

  describe "#dsSize" do
    it_behaves_like "a read-only datastream attribute"
    let(:method) { 'dsSize' }
  end

  describe "#dsVersionID" do
    it_behaves_like "a read-only datastream attribute"
    let(:method) { 'dsVersionID' }
  end
end

  describe "to_api_params" do

    describe "with existing properties" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
        @datastream.stub(:profile) { {'dsMIME' => 'application/rdf+xml', 'dsChecksumType' =>'DISABLED', 'dsVersionable'=>true, 'dsControlGroup'=>'M', 'dsState'=>'A'} }
      end
      it "should not set unchanged values except for mimeType" do
        @datastream.send(:to_api_params).should == {:mimeType=>'application/rdf+xml'}
      end
      it "should send changed params except those set to nil" do
        @datastream.dsLabel = nil
        @datastream.mimeType = 'application/json'
        @datastream.controlGroup = 'X'
        @datastream.send(:to_api_params).should == {:controlGroup=>"X", :mimeType=>"application/json"}
      end
    end


    describe "without existing properties" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
        @datastream.stub(:profile) { {} }
      end
      it "should compile parameters to hash" do
        @datastream.send(:to_api_params).should == {:checksumType=>"DISABLED", :versionable=>true,
         :controlGroup=>"M", :dsState=>"A"}
      end
      it "should not send parameters that are set to nil" do
        @datastream.dsLabel = nil
        @datastream.send(:to_api_params).should == {:checksumType=>"DISABLED", :versionable=>true,
         :controlGroup=>"M", :dsState=>"A"}
      end
    end
  end
end

