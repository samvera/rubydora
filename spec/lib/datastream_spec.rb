require 'spec_helper'
require 'stringio'

describe Rubydora::Datastream do
  before do
    @mock_repository = Rubydora::Fc3Service.new({})
    @mock_object = double(Rubydora::DigitalObject)
    @mock_object.stub(:repository => @mock_repository, :pid => 'pid', :new_record? => false)
  end

  describe "stream" do
    subject { Rubydora::Datastream.new @mock_object, 'dsid' }
    before do
      stub_response = double
      stub_response.stub(:read_body).and_yield("one1").and_yield('two2').and_yield('thre').and_yield('four')
      @mock_repository.should_receive(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_yield(stub_response) 
      prof = <<-XML
        <datastreamProfile>
          <dsSize>16</dsSize>
        </datastreamProfile>
      XML
      subject.profile = Rubydora::ProfileParser.parse_datastream_profile(prof)
    end
    it "should send the whold thing" do
      e = subject.stream()
      result = ''
      e.each do |blk|
        result << blk
      end
      result.should == 'one1two2threfour'
    end
    it "should send the whole thing when the range is open ended" do
      e = subject.stream(0)
      result = ''
      e.each do |blk|
        result << blk
      end
      result.should == 'one1two2threfour'
    end
    it "should get a range not starting at the beginning" do
      e = subject.stream(3, 13)
      result = ''
      e.each do |blk|
        result << blk
      end
      result.should == '1two2threfour'
    end
    it "should get a range not ending at the end" do
      e = subject.stream(4, 8)
      result = ''
      e.each do |blk|
        result << blk
      end
      result.should == 'two2thre'
    end
  end

  describe "create" do
    before(:each) do
      @mock_repository.stub(:datastream) { raise(RestClient::ResourceNotFound) }
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
    end

    it "should be new" do
      @datastream.new?.should == true
    end

    it "should not be dirty" do
      @datastream.changed?.should == false
    end

    it "should be dirty if datastream_will_change! is called" do
      @datastream.datastream_will_change!
      @datastream.changed?.should == true
    end

    it "should have default values" do
      @datastream.controlGroup == "M"
      @datastream.dsState.should == "A"
      @datastream.versionable.should be_true
      @datastream.changed.should be_empty
    end

    it "should allow default values to by specified later" do
      @datastream.dsState = 'A'
      @datastream.default_attributes = { :controlGroup => 'E', :dsState => 'I' }
      @datastream.controlGroup.should == 'E'
      @datastream.dsState.should == 'A'
    end

    describe "external?" do
      it "should test against controlGroup" do
        @datastream.should_not be_external
        @datastream.controlGroup = "E"
        @datastream.should be_external
      end
    end
    describe "redirect?" do
      it "should test against controlGroup" do
        @datastream.should_not be_redirect
        @datastream.controlGroup = "R"
        @datastream.should be_redirect
      end
    end
    describe "managed?" do
      it "should test against controlGroup" do
        # Managed is default
        @datastream.should be_managed
        @datastream.controlGroup = "X"
        @datastream.should_not be_managed
      end
    end
    describe "inline?" do
      it "should test against controlGroup" do
        @datastream.should_not be_inline
        @datastream.controlGroup = "X"
        @datastream.should be_inline
      end
    end

    it "should allow versionable to be set to false" do
      @datastream.versionable = false
      @datastream.versionable.should be_false
    end

    it "should be the current version" do
      @datastream.current_version?.should be_true
    end

    # it "should cast versionable to boolean" do
    #   @datastream.profile['versionable'] = 'true'
    #   @datastream.versionable.should be_true
    # end


    it "should call the appropriate api on save" do
      @datastream.stub(:content => 'content')
      @mock_repository.should_receive(:add_datastream).with(hash_including(:content => 'content', :pid => 'pid', :dsid => 'dsid', :controlGroup => 'M', :dsState => 'A'))
      @datastream.save
    end

    it "should be able to override defaults" do
      @mock_repository.should_receive(:add_datastream).with(hash_including(:controlGroup => 'E'))
      @datastream.controlGroup = 'E'
      @datastream.dsLocation = "uri:asdf"
      @datastream.save
    end
  end

  describe 'versionable' do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
    end
    it "should be true by default" do
      @mock_repository.should_receive(:datastream).and_return <<-XML
        <datastreamProfile>
        </datastreamProfile>
      XML
      @datastream.versionable.should be_true
    end

    it "should be true when it's returned as true" do
      @mock_repository.should_receive(:datastream).and_return <<-XML
        <datastreamProfile>
          <dsVersionable>true</dsVersionable>
        </datastreamProfile>
      XML
      @datastream.versionable.should be_true
    end

    it "should be false when it's returned as false" do
      @mock_repository.should_receive(:datastream).and_return <<-XML
        <datastreamProfile>
          <dsVersionable>false</dsVersionable>
        </datastreamProfile>
      XML
      @datastream.versionable.should be_false
    end
  end

  describe 'dsChecksumValid' do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
    end
    it "should be nil when it hasn't been set" do
      @mock_repository.should_receive(:datastream).with(hash_including(:validateChecksum => true)).and_return <<-XML
        <datastreamProfile>
        </datastreamProfile>
      XML
      @datastream.dsChecksumValid.should be_nil 
    end

    it "should be true when it's returned as true" do
      @mock_repository.should_receive(:datastream).with(hash_including(:validateChecksum => true)).and_return <<-XML
        <datastreamProfile>
          <dsChecksumValid>true</dsChecksumValid>
        </datastreamProfile>
      XML
      @datastream.dsChecksumValid.should be_true
    end

    it "should be false when it's returned as false" do
      @mock_repository.should_receive(:datastream).with(hash_including(:validateChecksum => true)).and_return <<-XML
        <datastreamProfile>
          <dsChecksumValid>false</dsChecksumValid>
        </datastreamProfile>
      XML
      @datastream.dsChecksumValid.should be_false
    end
  end

  describe "retrieve" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @mock_repository.stub(:datastream).and_return <<-XML
        <datastreamProfile>
          <dsLocation>some:uri</dsLocation>
          <dsLabel>label</dsLabel>
          <dsChecksumValid>true</dsChecksumValid>
        </datastreamProfile>
      XML
    end

    it "should not be new" do
      @datastream.stub :content_changed? => false
      @datastream.new?.should == false
      @datastream.changed?.should == false
    end

    it "should provide attribute defaults from dsProfile" do
      @datastream.dsLocation.should == 'some:uri'
      @datastream.dsLabel.should == 'label'
      @datastream.dsChecksumValid.should be true
    end

    it "should mediate access to datastream contents" do
      @mock_repository.should_receive(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('asdf') 
      @datastream.content.should == "asdf"
    end

    it "should not load contents if they say not to" do
      @mock_repository.should_not_receive(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid'))
      @datastream.local_or_remote_content(false).should be_nil
    end

    it "should rewind IO-type contents" do
      @mock_io = File.open('rubydora.gemspec')
      @mock_io.readline # start with a dirty file

      @datastream.content = @mock_io

      @datastream.content.should be_a(String)
      @datastream.content.should == File.read('rubydora.gemspec')

    end


  end

  describe "content changed behavior" do
    describe "for a managed datastream" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
        @mock_repository.stub(:datastream).and_return <<-XML
          <datastreamProfile>
            <dsLocation>some:uri</dsLocation>
            <dsLabel>label</dsLabel>
          </datastreamProfile>
        XML
      end

      it "should not be changed after a read-only access" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('asdf') 
        @datastream.content
        @datastream.content_changed?.should == false
      end
      it "should not load content just to check and see if it was changed." do
        @mock_repository.should_not_receive(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid'))
        @datastream.content_changed?.should == false
      end
      it "should be changed when the new content is different than the old content" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('asdf') 
        @datastream.content = "test"
        @datastream.content_changed?.should == true 
      end

      it "should not be changed when the new content is the same as the existing content (when eager-loading is enabled)" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('test') 
        @datastream.eager_load_datastream_content = true
        @datastream.content = "test"
        @datastream.content_changed?.should  == false 
      end

      it "should  be changed when the new content is the same as the existing content (without eager loading, the default)" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('test') 
        @datastream.content = "test"
        @datastream.content_changed?.should  == true
      end

      it "should not be changed when the new content is the same as the existing content (and we have accessed #content previously)" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('test') 
        @datastream.content
        @datastream.content = "test"
        @datastream.content_changed?.should  == false 
      end
    end

    describe "for an inline datastream" do
      before(:each) do
        @mock_repository.stub(:datastream).and_return <<-XML
          <datastreamProfile>
            <dsLocation>some:uri</dsLocation>
            <dsLabel>label</dsLabel>
          </datastreamProfile>
        XML
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid', :controlGroup => 'X'
      end
      it "should not be changed when the new content is the same as the existing content (when eager-loading is enabled)" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('<xml>test</xml>') 
        @datastream.eager_load_datastream_content = true
        @datastream.content = "<xml>test</xml>"
        @datastream.content_changed?.should  == false 
      end

      it "should  be changed when the new content is the same as the existing content (without eager loading, the default)" do
        @mock_repository.stub(:datastream_dissemination).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return('<xml>test</xml>') 
        @datastream.content = "<xml>test</xml>"
        @datastream.content_changed?.should  == true
      end
    end
  end

  describe "has_content?" do
    before(:each) do
      subject.stub(:new? => true)
    end

    subject { Rubydora::Datastream.new double(:pid => 'asdf', :new? => false), 'asdf' }
    it "should have content if it is persisted" do
      subject.stub(:new? => false)
      subject.should have_content     
    end

    it "should have content if it has content" do
      subject.content = "123"
      subject.should have_content     
    end

    context "it has a dsLocation" do
      before { subject.dsLocation = "urn:abc" }
      context "controlGroup 'E'" do
        before { subject.controlGroup = 'E' }
        it { should have_content }
      end
      context "controlGroup 'R'" do
        before { subject.controlGroup = 'R' }
        it { should have_content }
      end
      context "controlGroup 'M'" do
        before { subject.controlGroup = 'M' }
        it { should have_content }
      end
    end

    it "should not have content otherwise" do
      subject.stub(:content => nil)
      subject.should_not have_content     
    end
  end

  describe "update" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @mock_repository.stub(:datastream).and_return <<-XML
        <datastreamProfile>
          <dsLocation>some:uri</dsLocation>
          <dsLabel>label</dsLabel>
        </datastreamProfile>
      XML
    end

    describe "when content is unchanged" do
      before do
        @datastream.stub :content_changed? => false
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
    end

    describe "update when content is changed" do
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
  end

  describe "should check if an object is read-only" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      @datastream.stub :content_changed? => false
      @mock_repository.stub(:datastream).and_return <<-XML
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
    describe "when versions are in the repo" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
        @datastream.stub(:new? => false)
        @mock_repository.stub(:datastream_versions).and_return <<-XML
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
        Rubydora::Datastream.any_instance.stub(:new? => false)
        @datastream.versions.last.content
      end

      it "should be the current version" do
        @mock_repository.stub(:datastream).with(hash_including(:pid => 'pid', :dsid => 'dsid')).and_return <<-XML
          <datastreamProfile>
            <dsVersionID>dsid.1</dsVersionID>
            <dsCreateDate>2010-01-02T00:00:00.012Z</dsCreateDate>
          </datastreamProfile>
          XML
        @datastream.current_version?.should be_true
      end

      it "should be the current version if it's the first version" do
        @mock_repository.stub(:datastream).with(hash_including(:pid => 'pid', :dsid => 'dsid', :asOfDateTime =>'2010-01-02T00:00:00.012Z')).and_return <<-XML
          <datastreamProfile>
            <dsVersionID>dsid.1</dsVersionID>
            <dsCreateDate>2010-01-02T00:00:00.012Z</dsCreateDate>
          </datastreamProfile>
          XML
        @datastream.versions.first.current_version?.should be_true
      end

      it "should not be the current version if it's the second version" do
        @mock_repository.stub(:datastream).with(hash_including(:pid => 'pid', :dsid => 'dsid', :asOfDateTime => '2008-08-05T01:30:05.012Z')).and_return <<-XML
          <datastreamProfile>
            <dsVersionID>dsid.0</dsVersionID>
            <dsCreateDate>2008-08-05T01:30:05.012Z</dsCreateDate>
          </datastreamProfile>
          XML
        @datastream.versions[1].current_version?.should be_false
      end
    end
    describe "when no versions are found" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
        @mock_repository.stub(:datastream_versions).and_return nil
      end

      it "should have an emptylist of previous versions" do
        @datastream.versions.should be_empty
      end

      it "should be the current version" do
        @datastream.stub(:new? => false)
        @datastream.current_version?.should be_true
      end

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
          subject.should_receive(:profile) { { Rubydora::Datastream::DS_ATTRIBUTES[method.to_sym].to_s => 'qwerty' } }.twice
          subject.send(method).should == 'qwerty'
        end

        it "should fall-back to the set of default attributes" do
          mock_attr = { method.to_sym => 'zxcv' }
          subject.should_receive(:default_attributes).and_return(mock_attr)
          subject.send(method).should == 'zxcv'
        end
      end

      describe "setter" do
        before do
          subject.stub(:datastreams => [], :content_changed? => false)
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
          subject.stub(:profile) { { method => 'qwerty' } }
          subject.send(method).should == 'qwerty'
        end

        it "should fall-back to the set of default attributes" do
          mock_attr = { method.to_sym => 'zxcv' }
          subject.should_receive(:default_attributes).and_return(mock_attr)
          subject.send(method).should == 'zxcv'
        end
      end

    end

    describe "#controlGroup" do
      it_behaves_like "a datastream attribute"
      let(:method) { 'controlGroup' }
    end

    describe "#dsLocation" do
      it_behaves_like "a read-only datastream attribute"
      let(:method) { 'dsLocation' }

      subject { Rubydora::Datastream.new @mock_object, 'dsid' }

      it "should reject invalid URIs" do
        expect { subject.dsLocation = "this is a bad uri" }.to raise_error URI::InvalidURIError
      end

      it "should appear in the save request" do
          @mock_repository.should_receive(:modify_datastream).with(hash_including(method.to_sym => 'http://example.com'))
          subject.stub(:content_changed? => false)
          subject.dsLocation = 'http://example.com'
          subject.save
      end
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

  describe "profile=" do
    before(:each) do
      @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
    end
    it "should set the profile" do
      prof = <<-XML
        <datastreamProfile>
          <dsChecksumValid>true</dsChecksumValid>
        </datastreamProfile>
      XML
      @datastream.profile = Rubydora::ProfileParser.parse_datastream_profile(prof)
      @datastream.profile.should == {'dsChecksumValid' =>true}
    end
  end

  describe "profile" do
    describe "with a digital_object that doesn't have a repository" do
      ### see UnsavedDigitalObject in ActiveFedora
      before(:each) do
        @datastream = Rubydora::Datastream.new double(:foo), 'dsid'
      end
      it "should be empty if the digital_object doesn't have a repository" do
        @datastream.profile.should == {}
      end
    end
    describe "with a digital_object that has a repository" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
      end
      it "should accept a validateChecksum argument" do
        @mock_repository.should_receive(:datastream).with(hash_including(:validateChecksum => true)).and_return <<-XML
          <datastreamProfile>
            <dsChecksumValid>true</dsChecksumValid>
          </datastreamProfile>
        XML
        @datastream.profile(:validateChecksum=>true).should == {'dsChecksumValid' =>true}
      end
      it "should reraise Unauthorized errors" do
        @mock_repository.should_receive(:datastream).and_raise(RestClient::Unauthorized)
        lambda{@datastream.profile}.should raise_error(RestClient::Unauthorized)
      end

      describe "once it has a profile" do
        it "should use the profile from cache" do
          @mock_repository.should_receive(:datastream).once.and_return <<-XML
            <datastreamProfile>
              <dsChecksumValid>true</dsChecksumValid>
            </datastreamProfile>
          XML
          @datastream.profile().should == {'dsChecksumValid' =>true}
          #second time should not trigger the mock, which demonstrates that the profile is coming from cache.
          @datastream.profile().should == {'dsChecksumValid' =>true}
        end
        it "should re-fetch and replace the profile when validateChecksum is passed in, and there is no dsChecksumValid in the existing profile" do
          @mock_repository.should_receive(:datastream).once.and_return <<-XML
            <datastreamProfile>
              <dsLabel>The description of the content</dsLabel>
            </datastreamProfile>
          XML
          @mock_repository.should_receive(:datastream).with(hash_including(:validateChecksum => true)).once.and_return <<-XML
            <datastreamProfile>
              <dsLabel>The description of the content</dsLabel>
              <dsChecksumValid>true</dsChecksumValid>
            </datastreamProfile>
          XML
          @datastream.profile().should == {"dsLabel"=>"The description of the content"}
          @datastream.profile(:validateChecksum=>true).should == {"dsLabel"=>"The description of the content", 'dsChecksumValid' =>true}
          ## Third time should not trigger a mock, which demonstrates that the profile is coming from cache.
          @datastream.profile(:validateChecksum=>true)
        end
      end
    end
  end

  describe "to_api_params" do

    describe "with existing properties" do
      before(:each) do
        @datastream = Rubydora::Datastream.new @mock_object, 'dsid'
        @datastream.stub(:new? => false)
        @datastream.stub(:content_changed? => false)
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
        @datastream.stub(:new? => true )
        @datastream.stub(:local_or_remote_content => '123')
        @datastream.stub(:profile) { {} }
      end
      it "should compile parameters to hash" do
        @datastream.send(:to_api_params).should == {:versionable=>true, :controlGroup=>"M", :dsState=>"A", :content => '123' }
      end
      it "should not send parameters that are set to nil" do
        @datastream.dsLabel = nil
        @datastream.send(:to_api_params).should == {:versionable=>true, :controlGroup=>"M", :dsState=>"A", :content => '123' }
      end
    end
  end
end

