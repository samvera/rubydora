module Rubydora
  # Fedora SOAP API extension
  module Soap
    # @param [Rubydora::Repository] repository
    def self.extended repository
      require 'savon'
    end

    # SOAP API endpoint
    # @return [SOAP::RPC::Driver]
    def soap
     @soap ||= begin
                 client = Savon::Client.new do |wsdl, http|
                   wsdl.document = "#{ config[:url] }/wsdl?api=API-M"
                   http.auth.basic config[:user], config[:password]
                 end
               end
    end
  end
end
