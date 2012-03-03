require 'active_support/core_ext/hash/indifferent_access'

module Rubydora

  # Provide low-level access to the Fedora Commons REST API
  module RestApiClient
    
    include Rubydora::FedoraUrlHelpers
    include ActiveSupport::Benchmarkable

    VALID_CLIENT_OPTIONS = [:user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key]
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

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def next_pid options = {}
      options[:format] ||= 'xml'
      begin
        return client[next_pid_url(options)].post nil
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting nextPID. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def find_objects options = {}, &block_response
      raise ArgumentError,"Cannot have both :terms and :query parameters" if options[:terms] and options[:query]
      options[:resultFormat] ||= 'xml'

      begin
        resource = client[find_objects_url(options)]
        if block_given?
          resource.options[:block_response] = block_response
        end 
        return resource.get
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error finding objects. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object options = {}
      pid = options.delete(:pid)
      options[:format] ||= 'xml'
      begin
        return client[object_url(pid, options)].get
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def ingest options = {}
      pid = options.delete(:pid) || 'new'
      file = options.delete(:file)
      begin
        return client[object_url(pid, options)].post file, :content_type => 'text/xml'
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        logger.error "Unable to connect to Fedora at #{@client.url}"
        raise e
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error ingesting object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def export options = {}
      pid = options.delete(:pid)
      begin
        return client[export_object_url(pid, options)].get
      rescue RestClient::InternalServerError => e
        logger.error e.response
        raise FedoraInvalidRequest, "Error exporting object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def modify_object options = {}
      pid = options.delete(:pid)
      begin
        return client[object_url(pid, options)].put nil
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error modifying object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_object options = {}
      pid = options.delete(:pid)
      begin
        return client[object_url(pid, options)].delete
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error purging object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_versions options = {}
      pid = options.delete(:pid)
      options[:format] ||= 'xml'
      raise ArgumentError, "Must have a pid" unless pid
      begin
        return client[object_versions_url(pid, options)].get
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting versions for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_xml options = {}
      pid = options.delete(:pid)
      raise ArgumentError, "Missing required parameter :pid" unless pid
      options[:format] ||= 'xml'
      begin
        return client[object_xml_url(pid, options)].get
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting objectXML for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @option options [String] :asOfDateTime
    # @option options [String] :validateChecksum
    # @return [String]
    def datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      options[:format] ||= 'xml'
      begin
        val = nil
        message = dsid.nil? ? "Loaded datastream list for #{pid}" : "Loaded datastream #{pid}/#{dsid}"
        benchmark message, :level=>:debug do
          val = client[datastream_url(pid, dsid, options)].get
        end
        return val
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        logger.error "Unable to connect to Fedora at #{@client.url}"
        raise e
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting datastream '#{dsid}' for object #{pid}. See logger for details"
      end
    end

    alias_method :datastreams, :datastream

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def set_datastream_options options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      begin
        return client[datastream_url(pid, dsid, options)].put nil
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error setting datastream options on #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_versions options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      raise ArgumentError, "Must supply dsid" unless dsid
      options[:format] ||= 'xml'
      begin
        return client[datastream_history_url(pid, dsid, options)].get
      rescue RestClient::ResourceNotFound => e
        #404 Resource Not Found: No datastream history could be found. There is no datastream history for the digital object "changeme:1" with datastream ID of "descMetadata
        return nil
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting versions for datastream #{dsid} for object #{pid}. See logger for details"
      end
    end

    alias_method :datastream_history, :datastream_versions

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_dissemination options = {}, &block_response
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      method = options.delete(:method)
      method ||= :get
      raise self.class.name + "#datastream_dissemination requires a DSID" unless dsid
      begin
        resource = client[datastream_content_url(pid, dsid, options)]
        if block_given?
          resource.options[:block_response] = block_response
        end
        return resource.send(method)
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting dissemination for datastream #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def add_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:content)
      content_type = options.delete(:content_type) || options[:mimeType] || (MIME::Types.type_for(file.path).first if file.respond_to? :path) || 'application/octet-stream'
      begin
        return client[datastream_url(pid, dsid, options)].post file, :content_type => content_type.to_s, :multipart => true
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error adding datastream #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def modify_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:content)
      content_type = options.delete(:content_type) || options[:mimeType] || (MIME::Types.type_for(file.path).first if file.respond_to? :path) || 'application/octet-stream'

      rest_client_options = {}
      if file
        rest_client_options[:multipart] = true
        rest_client_options[:content_type] = content_type
      end

      begin
        return client[datastream_url(pid, dsid, options)].put(file, rest_client_options)
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error modifying datastream #{dsid} for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def purge_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      begin
        client[datastream_url(pid, dsid, options)].delete
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error purging datastream #{dsid} for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def relationships options = {}
      pid = options.delete(:pid) || options[:subject]
      raise ArgumentError, "Missing required parameter :pid" unless pid
      options[:format] ||= 'xml'
      begin
        return client[object_relationship_url(pid, options)].get
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting relationships for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def add_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      begin
        return client[new_object_relationship_url(pid, options)].post nil
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error adding relationship for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      begin
        return client[object_relationship_url(pid, options)].delete
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error purging relationships for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :sdef
    # @option options [String] :method
    # @return [String]
    def dissemination options = {}, &block_response
      pid = options.delete(:pid)
      sdef = options.delete(:sdef)
      method = options.delete(:method)
      options[:format] ||= 'xml' unless pid and sdef and method
      begin
        resource = client[dissemination_url(pid,sdef,method,options)]
        if block_given?
          resource.options[:block_response] = block_response
        end
        return resource.get
      rescue RestClient::InternalServerError => e
        logger.error e.response
        logger.flush if logger.respond_to? :flush
        raise FedoraInvalidRequest, "Error getting dissemination for #{pid}. See logger for details"
      end
    end
  end
end
