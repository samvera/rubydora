module Rubydora::RestApiClient
  module V33
    def soap
     return @soap if @soap
     gem "soap4r"
     require 'soap/wsdlDriver'

     @soap = SOAP::WSDLDriverFactory.new("#{ config[:url] }/wsdl?api=API-M").create_rpc_driver
     @soap.options['protocol.http.basic_auth'] << [config[:url], config[:user], config[:password]]

     @soap
       
    end
    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def relationships options = {}
      nil
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def add_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      self.soap.addRelationship(:pid => pid, :relationship => options[:predicate], :object => options[:object], :isLiteral => false, :datatype => nil)
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      self.soap.purgeRelationship(:pid => pid, :relationship => options[:predicate], :object => options[:object], :isLiteral => false, :datatype => nil)
    end

  end
end
