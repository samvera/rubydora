module Rubydora
  # Fedora SOAP API extension
  module Soap
    # @param [Rubydora::Repository] repository
    def self.extended repository
      gem "soap4r"
      require 'soap/wsdlDriver'
    end

    # SOAP API endpoint
    # @return [SOAP::RPC::Driver]
    def soap
     return @soap if @soap

     @soap = SOAP::WSDLDriverFactory.new("#{ config[:url] }/wsdl?api=API-M").create_rpc_driver
     @soap.options['protocol.http.basic_auth'] << [config[:url], config[:user], config[:password]]

     @soap
    end
  end
end
