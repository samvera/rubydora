module Rubydora
  # Fedora Repository object that provides API access
  class Repository
    include ResourceIndex
    include RestApiClient

    # repository configuration (see #initialize)
    attr_reader :config

    # @param [Hash] options
    # @option options [String] :url
    # @option options [String] :user
    # @option options [String] :password
    def initialize options = {}
      @config = options
      load_api_abstraction
    end

    # {include:DigitalObject.find}
    def find pid
      DigitalObject.find(pid, self)
    end

    def profile
      @profile ||= begin
        profile_xml = client['describe?xml=true'].get
        profile_xml.gsub! '<fedoraRepository', '<fedoraRepository xmlns="http://www.fedora.info/definitions/1/0/access/"' unless profile_xml =~ /xmlns=/
        doc = Nokogiri::XML(profile_xml)
        xmlns = { 'access' => "http://www.fedora.info/definitions/1/0/access/"  }
        h = doc.xpath('/access:fedoraRepository/*', xmlns).inject({}) do |sum, node|
                     sum[node.name] ||= []
                     case node.name
                       when "repositoryPID"
                         sum[node.name] << Hash[*node.xpath('access:*', xmlns).map { |x| [node.name, node.text]}.flatten]
                       else
                         sum[node.name] << node.text
                     end
                     sum
                   end
        h.select { |key, value| value.length == 1 }.each do |key, value|
          next if key == "objModels"
          h[key] = value.first
        end

        h
      rescue
        nil
      end
    end

    def version
      @version ||= profile['repositoryVersion'].to_f rescue nil
    end

    def ping
      raise "Unable to establish connection to Fedora Repository" unless profile
    end

    protected

    def load_api_abstraction
      return unless version

      if version <= 3.0
      end

      if version < 3.4
        require 'rubydora/rest_api_client/v33'
        self.include Rubydora::RestApiClient::V33
      end

      true
    end

  end
end
