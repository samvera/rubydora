require 'spec_helper'

describe Rubydora::ExtensionParameters do
  describe "extension parameters" do
    class MockExtensionParametersClass
      include Rubydora::Callbacks
      register_callback :after_initialize
      include Rubydora::ExtensionParameters
    end

    it "should have extension parameters at the class level" do
      MockExtensionParametersClass.extension_parameters[:a] = 1 

      MockExtensionParametersClass.extension_parameters.should == { :a => 1 }

    end
  end

  describe "DigitalObject" do
    module FakeExtension
    end

    module OtherFakeExtension

    end
    before(:each) do
      @mock_repository = mock()
    end

    after(:each) do
      Rubydora::DigitalObject.registered_extensions = []
    end

    it "should be extendable" do
      Rubydora::DigitalObject.use_extension FakeExtension
      @object = Rubydora::DigitalObject.new 'pid', @mock_repository
      @object.is_a?(FakeExtension).should == true
    end

    it "should be extendable conditionally" do
      Rubydora::DigitalObject.use_extension(FakeExtension) { |x| true }
      Rubydora::DigitalObject.use_extension(OtherFakeExtension) { |x| false }
      @object = Rubydora::DigitalObject.new 'pid', @mock_repository
      @object.is_a?(FakeExtension).should == true
      @object.is_a?(OtherFakeExtension).should == false
    end

    it "should be able to introspect object profiles" do
      @mock_repository.should_receive(:object).any_number_of_times.with({:pid => 'pid'}).and_return <<-XML
      <objectProfile>
        <a>1</a>
      </objectProfile>
      XML
      Rubydora::DigitalObject.use_extension(FakeExtension) { |x| x.profile['a'] == '1' }
      @object = Rubydora::DigitalObject.new 'pid', @mock_repository
      @object.is_a?(FakeExtension).should == true
    end
  end
end

