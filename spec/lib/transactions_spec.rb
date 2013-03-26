require 'spec_helper'

describe Rubydora::Transactions do
  

  subject { 
    Rubydora::Repository.any_instance.stub(:version).and_return(100)
    repository = Rubydora::Repository.new :url => 'http://example.org'
  }

  describe "#transaction_is_redundant?" do
    it "should throw away transactions messages if the object was ingested or purged previously" do
      subject.client.stub_chain(:[], :post).and_return 'asdf'
      subject.client.stub_chain(:[], :put).and_return 'asdf'
      subject.client.stub_chain(:[], :delete)

        # this should be squelched
      subject.should_not_receive(:export).with(hash_including(:pid => 'asdf', :context => :archive))
      
      subject.transaction do |t|
        subject.ingest :pid => 'asdf', :file => '<a />'
        subject.purge_object :pid => 'asdf'
        subject.modify_datastream :pid => 'asdf', :dsid => 'mydsid'


        subject.should_receive(:purge_object).with(hash_including(:pid => 'asdf'))

        # this should be squelched
        subject.should_not_receive(:ingest).with(hash_including(:pid => 'asdf', :file => '<a />'))

        t.rollback
      end
    end
  end

  describe "#rollback" do

    it "should fire a after_rollback hook" do
      i = 0
      Rubydora::Transaction.after_rollback do
        i+=1
      end

      subject.transaction do |t|
        subject.append_to_transactions_log :asdf, :pid => 'asdf'
        subject.append_to_transactions_log :asdf, :pid => 'asdf'
        subject.append_to_transactions_log :asdf, :pid => 'asdf'
        subject.append_to_transactions_log :asdf, :pid => 'asdf'
        subject.append_to_transactions_log :asdf, :pid => 'asdf'
        subject.append_to_transactions_log :asdf, :pid => 'asdf'
        t.rollback
      end

      i.should == 6
    end

    it "ingest" do
      subject.client.stub_chain(:[], :post).and_return 'asdf'
      subject.should_receive(:purge_object).with(hash_including(:pid => 'asdf'))

      subject.transaction do |t|

        subject.ingest :pid => 'asdf', :file => '<a />'

        t.rollback
      end
    end

    it "modify_object" do
      subject.client.stub_chain(:[], :put).and_return 'asdf'

      mock_object = double('Rubydora::DigitalObject', :state => 'A', :ownerId => '567', :logMessage => 'dfghj')
      subject.should_receive(:find).with('asdf').and_return mock_object
      

      subject.transaction do |t|
        subject.modify_object :pid => 'asdf', :state => 'I', :ownerId => '123', :logMessage => 'changing asdf'

        subject.should_receive(:modify_object).with(hash_including(:pid => 'asdf', :state => 'A', :ownerId => '567', :logMessage => 'reverting'))
        t.rollback
      end
    end

    it "purge_object" do
      subject.client.stub_chain(:[], :delete)

      subject.should_receive(:export).with(hash_including(:pid => 'asdf', :context => :archive)).and_return '<xml />'
      subject.should_receive(:ingest).with(hash_including(:pid => 'asdf', :file => '<xml />'))

      subject.transaction do |t|
        subject.purge_object :pid => 'asdf'

        t.rollback
      end
    end

    it "add_datastream" do
      subject.client.stub_chain(:[], :post)
      subject.should_receive(:purge_datastream).with(hash_including(:pid => 'asdf', :dsid => 'mydsid'))

      subject.transaction do |t|
        subject.add_datastream :pid => 'asdf', :dsid => 'mydsid'

        t.rollback
      end
    end

    it "modify_datastream" do
      subject.client.stub_chain(:[], :put)

      subject.should_receive(:export).with(hash_including(:pid => 'asdf', :context => :archive)).and_return '<xml />'
      subject.should_receive(:purge_object).with(hash_including(:pid => 'asdf'))
      subject.should_receive(:ingest).with(hash_including(:pid => 'asdf', :file => '<xml />'))

      subject.transaction do |t|
        subject.modify_datastream :pid => 'asdf', :dsid => 'mydsid'

        t.rollback
      end
    end

    it "set_datastream_options" do
      subject.client.stub_chain(:[], :put)

      mock_object = double('Rubydora::DigitalObject')
      mock_object.stub_chain(:datastreams, :[], :versionable).and_return(false)
      subject.should_receive(:find).with('asdf').and_return mock_object

      subject.transaction do |t|
        subject.set_datastream_options :pid => 'asdf', :dsid => 'mydsid', :versionable => true

        subject.should_receive(:set_datastream_options).with(hash_including(:pid => 'asdf', :versionable => false, :dsid => 'mydsid'))

        t.rollback
      end
    end

    it "purge_datastream" do
      subject.client.stub_chain(:[], :delete)

      subject.should_receive(:export).with(hash_including(:pid => 'asdf', :context => :archive)).and_return '<xml />'
      subject.should_receive(:ingest).with(hash_including(:pid => 'asdf', :file => '<xml />'))

      subject.transaction do |t|
        subject.purge_datastream :pid => 'asdf', :dsid => 'mydsid'

        t.rollback
      end
    end

    it "add_relationship" do
      subject.client.stub_chain(:[], :post)
      subject.should_receive(:purge_relationship).with(hash_including(:subject => 'subject', :predicate => 'predicate', :object => 'object'))

      subject.transaction do |t|
        subject.add_relationship :subject => 'subject', :predicate => 'predicate', :object => 'object'
        t.rollback
      end
    end

    it "purge_relationship" do
      subject.client.stub_chain(:[], :delete)
      subject.should_receive(:add_relationship).with(hash_including(:subject => 'subject', :predicate => 'predicate', :object => 'object'))

      subject.transaction do |t|
        subject.purge_relationship :subject => 'subject', :predicate => 'predicate', :object => 'object'
        t.rollback
      end
    end
  end
end
