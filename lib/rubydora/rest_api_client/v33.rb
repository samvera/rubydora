module Rubydora::RestApiClient
  # Fall-back implementations for fcrepo < 3.4
  module V33
    # SOAP API endpoint
    # @return [SOAP::WSDLDriverFactory]
    def soap
     return @soap if @soap
     gem "soap4r"
     require 'soap/wsdlDriver'

     @soap = SOAP::WSDLDriverFactory.new("#{ config[:url] }/wsdl?api=API-M").create_rpc_driver
     @soap.options['protocol.http.basic_auth'] << [config[:url], config[:user], config[:password]]

     @soap
       
    end

    # {include:RestApiClient#relationships}
    def relationships options = {}
      nil
    end

    # {include:RestApiClient#add_relationship}
    def add_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      self.soap.addRelationship(:pid => pid, :relationship => options[:predicate], :object => options[:object], :isLiteral => false, :datatype => nil)
    end

    # {include:RestApiClient#purge_relationship}
    def purge_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      self.soap.purgeRelationship(:pid => pid, :relationship => options[:predicate], :object => options[:object], :isLiteral => false, :datatype => nil)
    end

  end
end
