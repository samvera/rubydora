require 'active_support/core_ext/hash/indifferent_access'

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
    # @option options [Boolean] :validateChecksum
    def initialize options = {}
      @config = options.symbolize_keys
      check_repository_version!
    end

    # {include:DigitalObject.find}
    def find pid
      DigitalObject.find(pid, self)
    end

    # High-level access to the Fedora find_objects API
    #
    # @params [String] query
    # @params [Hash] options
    # @yield [DigitalObject] Yield a DigitalObject for each search result
    def search query, options = {}, &block
      return to_enum(:search, query, options).to_a unless block_given?
      
      sessionToken = nil 
      doc = nil

      begin 
        sessionOptions = {}
        sessionOptions[:sessionToken] = sessionToken unless sessionToken.nil? or sessionToken.blank?

        response = self.find_objects(options.merge(:query => query, :resultFormat => 'xml', :pid => true).merge(sessionOptions))

        doc = Nokogiri::XML(response)
        doc.xpath('//xmlns:objectFields/xmlns:pid', doc.namespaces).each { |pid| obj = self.find(pid.text); block.call(obj) }

        sessionToken = doc.xpath('//xmlns:listSession/xmlns:token', doc.namespaces).text
      end until sessionToken.nil? or sessionToken.empty? or doc.xpath('//xmlns:resultList/xmlns:objectFields', doc.namespaces).empty?

    end

    # {include:DigitalObject.create}
    def create pid, options = {}
      DigitalObject.create(pid, options = {}, self)
    end

    # repository profile (from API-A-LITE data)
    # @return [Hash]
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

    # @return [Float] repository version
    def version
      @version ||= profile['repositoryVersion'].to_f rescue nil
    end

    # Raise an error if unable to connect to the API endpoint
    def ping
      raise "Unable to establish connection to Fedora Repository" unless profile
      true
    end

    protected

    # Load fallback API implementations for older versions of Fedora
    def check_repository_version!
      return unless version

      if version < 3.4
        raise "You're connecting to a Fedora #{version} repository. Rubydora requires Fedora >= 3.4"
      end

      true
    end

  end
end
