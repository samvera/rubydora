require 'spec_helper'
require 'rubydora/ext/solr'

describe Rubydora::Ext::Solr do
  before(:all) do
    Rubydora::Ext::Solr.load
  end
  describe "load" do
    it "should load mixins" do
      @mock_repository = mock(Rubydora::Repository)
      obj = Rubydora::DigitalObject.new('pid', @mock_repository)
      obj.should be_a_kind_of(Rubydora::Ext::Solr::DigitalObjectMixin)
    end
  end

  describe "solr_mapping_logic" do
    class MockSolrMappingClass

    end 
    before(:each) do
       Rubydora::Ext::Solr.load :digital_object => MockSolrMappingClass
    end

    it "should provide a class-level step list" do
      MockSolrMappingClass.solr_mapping_logic.should_not be_empty
    end

    it "should be overridable on the class level" do
      expect { MockSolrMappingClass.solr_mapping_logic << :a }.to change{MockSolrMappingClass.solr_mapping_logic.length}.by(1)
    end

    it "should be overridable on the instance level" do
      MockSolrMappingClass.solr_mapping_logic = []
      mock = MockSolrMappingClass.new

      mock.solr_mapping_logic.should be_empty
      mock.solr_mapping_logic << :a
      mock.solr_mapping_logic.should == [:a]
      MockSolrMappingClass.solr_mapping_logic.should == []
    end

  end

  describe "to_solr" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.new('pid', @mock_repository)
    end
    it "should call the members of solr_mapping_logic" do
      @object.should_receive(:solr_mapping_logic).and_return([:mock_solr_step, :another_mock_solr_step])
      @object.should_receive(:mock_solr_step)
      @object.should_receive(:another_mock_solr_step)
      @object.to_solr
    end

    it "should allow steps to modify the resulting solr document" do
      @object.should_receive(:solr_mapping_logic).and_return([:mock_solr_step, :another_mock_solr_step])
      @object.stub(:mock_solr_step) do |doc|
        doc[:a] = 'a'
        doc[:b] = 0
      end

      @object.stub(:another_mock_solr_step) do |doc|
        doc[:b] = 'b'
      end
    
      @object.to_solr.should == { :a => 'a', :b => 'b'}
    end
  end

  describe "object_profile_to_solr" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.new('pid', @mock_repository)
    end

    it "should map the pid and id" do
      @object.should_receive(:profile).and_return({})
      doc = {}
      @object.object_profile_to_solr(doc)

      doc['id'].should == 'pid'
      doc['pid_s'].should == 'pid'
    end

    it "should map the profile hash to generic document fields" do
      @object.should_receive(:profile).and_return({'a' => 1, 'b' => 2})
      doc = {}
      @object.object_profile_to_solr(doc)
      doc['a_s'].should == 1
      doc['b_s'].should == 2
    end
  end

  describe "datastreams_to_solr" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.new('pid', @mock_repository)
    end

    it "should map the list of datastreams" do
      @mock_ds = mock(Rubydora::Datastream)
      @mock_ds2 = mock(Rubydora::Datastream)

      @mock_ds.should_receive(:to_solr).with(instance_of(Hash))
      @mock_ds2.should_receive(:to_solr).with(instance_of(Hash))
      @object.should_receive(:datastreams).and_return(:a => @mock_ds, :b => @mock_ds2)
      doc = {}
      @object.datastreams_to_solr(doc)

      doc['disseminates_s'].should == [:a, :b]
    end

    it "should let the datastreams inject any document attributes" do
      @mock_ds = mock(Rubydora::Datastream)

      @mock_ds.should_receive(:to_solr) do |doc|
        doc['a'] = 1
      end
      @object.should_receive(:datastreams).and_return(:a => @mock_ds)
      doc = {}
      @object.datastreams_to_solr(doc)

      doc['a'].should == 1
    end
  end

  describe "relations_to_solr" do
    before(:each) do
      @mock_repository = mock(Rubydora::Repository)
      @object = Rubydora::DigitalObject.new('pid', @mock_repository)
    end

    it "should lazily map relationships from SPARQL" do
      @object.repository.should_receive(:sparql).and_return([{'relation' => '...#isPartOf', 'object' => 'info:fedora/test:pid'}])
      doc = {}
      @object.relations_to_solr(doc)
      doc['ri_isPartOf_s'].should == ['info:fedora/test:pid']
    end
  end


end

