require 'active_support/core_ext/hash/indifferent_access'

module Rubydora
  # Fedora Repository object that provides API access
  class Repository
    include ResourceIndex

    attr_writer :api
    def api
      @api ||= driver.new(config)
    end

    # Eventually driver can decide between Fc3Service and Fc4Service
    def driver
      Fc3Service
    end

    delegate :client, :transaction, :ingest, :find_objects, :purge_object, :modify_object,
      :datastreams, :add_datastream, :modify_datastream, :set_datastream_options, 
      :datastream_dissemination, :purge_datastream,
      :repository_profile, :object_profile, :datastream_profile, :versions_for_datastream, :versions_for_object, to: :api

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

    def find_or_initialize pid
      DigitalObject.find_or_initialize(pid, self)
    end

    # Reserve a new pid for the object
    # @params [Hash] options
    # @option options [String] :namespace the namespece for the pid
    def mint(options={})
      d = Nokogiri::XML(next_pid(options))
      d.xpath('//fedora:pid', 'fedora' => 'http://www.fedora.info/definitions/1/0/management/').text
    end

    # High-level access to the Fedora find_objects API
    #
    # @params [String] query
    # @params [Hash] options
    # @yield [DigitalObject] Yield a DigitalObject for each search result, skipping forbidden objects
    def search query, options = {}, &block
      return to_enum(:search, query, options).to_a unless block_given?
      
      sessionToken = nil 
      doc = nil

      begin 
        sessionOptions = {}
        sessionOptions[:sessionToken] = sessionToken unless sessionToken.nil? or sessionToken.blank?

        response = self.find_objects(options.merge(:query => query, :resultFormat => 'xml', :pid => true).merge(sessionOptions))

        doc = Nokogiri::XML(response)
        doc.xpath('//xmlns:objectFields/xmlns:pid', doc.namespaces).each do |pid|
          begin
            obj = self.find(pid.text);
          rescue RestClient::Unauthorized
            next
          end
          block.call(obj)
        end

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
      @profile ||= repository_profile
    end

    # @return [Float] repository version
    def version
      @version ||= repository_profile['repositoryVersion'].to_f rescue nil
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
