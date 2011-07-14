require 'spec_helper'

describe Rubydora::Soap do
  before(:all) do
    @repository = Rubydora.connect({ :url => 'http://localhost:8080/fedora', :user => 'fedoraAdmin', :password => 'fedoraAdmin' })
    @repository.send(:extend, Rubydora::Soap)
  end

  it "should provide a SOAP endpoint accessor" do
     @repository.soap.should be_a_kind_of(Savon::Client)
  end
end
