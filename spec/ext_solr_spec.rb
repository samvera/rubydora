require 'spec_helper'
require 'rubydora/ext/solr'

describe Rubydora::Ext::Solr do
  describe "load" do
    it "should load mixins" do
      Rubydora::Ext::Solr.load
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
end

