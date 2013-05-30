require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/class'
require 'active_support/core_ext/module'

module Rubydora

  # Provide low-level access to the Fedora Commons REST API
  module RestApiClient
    
    include Rubydora::FedoraUrlHelpers
    extend ActiveSupport::Concern
    include ActiveSupport::Benchmarkable    
    extend Deprecation



    VALID_CLIENT_OPTIONS = [:user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key]

    included do
      include ActiveSupport::Rescuable


      rescue_from RestClient::InternalServerError do |e|
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "See logger for details"
      end

      rescue_from Errno::ECONNREFUSED, Errno::EHOSTUNREACH do |exception|
        logger.error "Unable to connect to Fedora at #{@client.url}"
        raise exception
      end

      include Hooks
      [:ingest, :modify_object, :purge_object, :set_datastream_options, :add_datastream, :modify_datastream, :purge_datastream, :add_relationship, :purge_relationship].each do |h|
        define_hook "before_#{h}".to_sym
      end

      define_hook :after_ingest
      include Transactions
    end

    # Create an authorized HTTP client for the Fedora REST API
    # @param [Hash] config
    # @option config [String] :url
    # @option config [String] :user
    # @option config [String] :password
    # @return [RestClient::Resource]
    #TODO trap for these errors specifically: RestClient::Request::Unauthorized, Errno::ECONNREFUSED
    def client config = {}
      client_config = self.config.merge(config)
      client_config.symbolize_keys!
      if config.empty? or @config_hash.nil? or (client_config.hash == @config_hash)
        @config_hash = client_config.hash
        url = client_config[:url]
        client_config.delete_if { |k,v| not VALID_CLIENT_OPTIONS.include?(k) }
        client_config[:open_timeout] ||= client_config[:timeout]
        @client ||= RestClient::Resource.new(url, client_config)
      else
        raise ArgumentError, "Attemping to re-initialize #{self.class}#client with different configuration parameters"
      end
    end

    def describe options = {}
      query_options = options.dup
      query_options[:xml] ||= 'true'
      client[describe_repository_url(query_options)].get
    rescue Exception => exception
      rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def next_pid options = {}
      query_options = options.dup
      query_options[:format] ||= 'xml'
      client[next_pid_url(query_options)].post nil
    rescue Exception => exception
      rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def find_objects options = {}, &block_response
      query_options = options.dup
      raise ArgumentError,"Cannot have both :terms and :query parameters" if query_options[:terms] and query_options[:query]
      query_options[:resultFormat] ||= 'xml'

      resource = client[find_objects_url(query_options)]
      if block_given?
        resource.query_options[:block_response] = block_response
      end 
      return resource.get
    rescue Exception => exception
      rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      query_options[:format] ||= 'xml'
      client[object_url(pid, query_options)].get
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def ingest options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)

      if pid.nil?
        return mint_pid_and_ingest options
      end

      file = query_options.delete(:file)
      assigned_pid = client[object_url(pid, query_options)].post((file.dup if file), :content_type => 'text/xml')
      run_hook :after_ingest, :pid => assigned_pid, :file => file, :options => options
      assigned_pid
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    def mint_pid_and_ingest options = {}
      query_options = options.dup
      file = query_options.delete(:file)

      assigned_pid = client[new_object_url(query_options)].post((file.dup if file), :content_type => 'text/xml')
      run_hook :after_ingest, :pid => assigned_pid, :file => file, :options => options
      assigned_pid
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def export options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      raise ArgumentError, "Must have a pid" unless pid
      client[export_object_url(pid, query_options)].get
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def modify_object options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      run_hook :before_modify_object, :pid => pid, :options => options
      client[object_url(pid, query_options)].put nil
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_object options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      run_hook :before_purge_object, :pid => pid, :options => options
      client[object_url(pid, query_options)].delete
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_versions options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      query_options[:format] ||= 'xml'
      raise ArgumentError, "Must have a pid" unless pid
      client[object_versions_url(pid, query_options)].get
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_xml options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      raise ArgumentError, "Missing required parameter :pid" unless pid
      query_options[:format] ||= 'xml'
      client[object_xml_url(pid, query_options)].get
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @option options [String] :asOfDateTime
    # @option options [String] :validateChecksum
    # @return [String]
    def datastream options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      raise ArgumentError, "Missing required parameter :pid" unless pid

      if dsid.nil?
        #raise ArgumentError, "Missing required parameter :dsid" unless dsid
        Deprecation.warn(RestApiClient, "Calling Rubydora::RestApiClient#datastream without a :dsid is deprecated, use #datastreams instead")
        return datastreams(options)
      end
      query_options[:format] ||= 'xml'
      val = nil
      benchmark "Loaded datastream profile #{pid}/#{dsid}", :level=>:debug do
        val = client[datastream_url(pid, dsid, query_options)].get
      end

      val
    rescue RestClient::Unauthorized => e
      logger.error "Unauthorized at #{client.url}/#{datastream_url(pid, dsid, query_options)}"
      raise e
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    def datastreams options = {}
      unless options[:dsid].nil?
        #raise ArgumentError, "Missing required parameter :dsid" unless dsid
        Deprecation.warn(RestApiClient, "Calling Rubydora::RestApiClient#datastreams with a :dsid is deprecated, use #datastream instead")
        return datastream(options)
      end
      query_options = options.dup
      pid = query_options.delete(:pid)
      raise ArgumentError, "Missing required parameter :pid" unless pid
      query_options[:format] ||= 'xml'
      val = nil
      benchmark "Loaded datastream list for #{pid}", :level=>:debug do
        val = client[datastreams_url(pid, query_options)].get
      end

      val
    rescue RestClient::Unauthorized => e
      logger.error "Unauthorized at #{client.url}/#{datastreams_url(pid, query_options)}"
      raise e
    rescue Exception => exception
        rescue_with_handler(exception) || raise

    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def set_datastream_options options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      run_hook :before_set_datastream_options, :pid => pid, :dsid => dsid, :options => options
      client[datastream_url(pid, dsid, query_options)].put nil
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_versions options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      raise ArgumentError, "Must supply dsid" unless dsid
      query_options[:format] ||= 'xml'
      client[datastream_history_url(pid, dsid, query_options)].get
    rescue RestClient::ResourceNotFound => e
      #404 Resource Not Found: No datastream history could be found. There is no datastream history for the digital object "changeme:1" with datastream ID of "descMetadata
      return nil
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    alias_method :datastream_history, :datastream_versions

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_dissemination options = {}, &block_response
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      method = query_options.delete(:method)
      method ||= :get
      raise self.class.name + "#datastream_dissemination requires a DSID" unless dsid
      if block_given?
        resource = safe_subresource(datastream_content_url(pid, dsid, query_options), :block_response => block_response)
      else
        resource = client[datastream_content_url(pid, dsid, query_options)]
      end
      val = nil
      benchmark "Loaded datastream content #{pid}/#{dsid}", :level=>:debug do
        val = resource.send(method)
      end
      val
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def add_datastream options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      file = query_options.delete(:content)
      # In ruby 1.8.7 StringIO (file) responds_to? :path, but it always returns nil,  In ruby 1.9.3 StringIO doesn't have path.
      # When we discontinue ruby 1.8.7 support we can remove the `|| ''` part.
      content_type = query_options.delete(:content_type) || query_options[:mimeType] || (MIME::Types.type_for(file.path || '').first if file.respond_to? :path) || 'application/octet-stream'
      run_hook :before_add_datastream, :pid => pid, :dsid => dsid, :file => file, :options => options
      str = file.respond_to?(:read) ? file.read : file
      file.rewind if file.respond_to?(:rewind)
      client[datastream_url(pid, dsid, query_options)].post(str, :content_type => content_type.to_s, :multipart => true)
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def modify_datastream options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      file = query_options.delete(:content)
      # In ruby 1.8.7 StringIO (file) responds_to? :path, but it always returns nil,  In ruby 1.9.3 StringIO doesn't have path.
      # When we discontinue ruby 1.8.7 support we can remove the `|| ''` part.
      content_type = query_options.delete(:content_type) || query_options[:mimeType] || (MIME::Types.type_for(file.path || '').first if file.respond_to? :path) || 'application/octet-stream'

      rest_client_options = {}
      if file
        rest_client_options[:multipart] = true
        rest_client_options[:content_type] = content_type
      end

      run_hook :before_modify_datastream, :pid => pid, :dsid => dsid, :file => file, :content_type => content_type, :options => options
      str = file.respond_to?(:read) ? file.read : file
      file.rewind if file.respond_to?(:rewind)
      client[datastream_url(pid, dsid, query_options)].put(str, rest_client_options)

    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def purge_datastream options = {}
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      run_hook :before_purge_datastream, :pid => pid, :dsid => dsid
      client[datastream_url(pid, dsid, query_options)].delete
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def relationships options = {}
      query_options = options.dup
      pid = query_options.delete(:pid) || query_options[:subject]
      raise ArgumentError, "Missing required parameter :pid" unless pid
      query_options[:format] ||= 'xml'
      client[object_relationship_url(pid, query_options)].get
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def add_relationship options = {}
      query_options = options.dup
      pid = query_options.delete(:pid) || query_options[:subject]
      run_hook :before_add_relationship, :pid => pid, :options => options
      client[new_object_relationship_url(pid, query_options)].post nil
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_relationship options = {}
      query_options = options.dup
      pid = query_options.delete(:pid) || query_options[:subject]
      run_hook :before_purge_relationship, :pid => pid, :options => options
      client[object_relationship_url(pid, query_options)].delete
    rescue Exception => exception
        rescue_with_handler(exception) || raise
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :sdef
    # @option options [String] :method
    # @return [String]
    def dissemination options = {}, &block_response
      query_options = options.dup
      pid = query_options.delete(:pid)
      sdef = query_options.delete(:sdef)
      method = query_options.delete(:method)
      query_options[:format] ||= 'xml' unless pid and sdef and method
      if block_given?
        resource = safe_subresource(dissemination_url(pid,sdef,method,query_options), :block_response => block_response)
      else
        resource = client[dissemination_url(pid,sdef,method,query_options)]
      end
      resource.get

    rescue Exception => exception
        rescue_with_handler(exception) || raise

    end
    
    def safe_subresource(subresource, options=Hash.new)
      url = client.concat_urls(client.url, subresource)
      options = client.options.dup.merge! options
      block = client.block
      if block
        client.class.new(url, options, &block)
      else
        client.class.new(url, options)
      end
    end
  end
end
