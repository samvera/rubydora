module Rubydora

  # Provide low-level access to the Fedora Commons REST API
  module RestApiClient
    # Fedora API documentation available at {https://wiki.duraspace.org/display/FCR30/REST+API}
    API_DOCUMENTATION = 'https://wiki.duraspace.org/display/FCR30/REST+API'
    # Create an authorized HTTP client for the Fedora REST API
    # @param [Hash] config
    # @option config [String] :url
    # @option config [String] :user
    # @option config [String] :password
    # @return [RestClient::Resource]
    def client config = {}
      config = self.config.merge(config)
      @client ||= RestClient::Resource.new(config[:url], :user => config[:user], :password => config[:password], :timeout => config[:timeout], :open_timeout => config[:timeout])
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def next_pid options = {}
      options[:format] ||= 'xml'
      client[url_for(object_url() + "/nextPID", options)].post nil
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def find_objects options = {}
      raise "" if options[:terms] and options[:query]
      options[:resultFormat] ||= 'xml'

      client[object_url(nil, options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object options = {}
      pid = options.delete(:pid)
      options[:format] ||= 'xml'
      client[object_url(pid, options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def ingest options = {}
      pid = options.delete(:pid) || 'new'
      file = options.delete(:file)
      client[object_url(pid, options)].post file, :content_type => 'text/xml'
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def modify_object options = {}
      pid = options.delete(:pid)
      client[object_url(pid, options)].put nil
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_object options = {}
      pid = options.delete(:pid)
      client[object_url(pid, options)].delete
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_versions options = {}
      pid = options.delete(:pid)
      options[:format] ||= 'xml'
      raise "" unless pid
      client[url_for(object_url(pid) + "/versions", options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_xml options = {}
      pid = options.delete(:pid)
      raise "" unless pid
      options[:format] ||= 'xml'
      client[url_for(object_url(pid) + "/objectXML", options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      options[:format] ||= 'xml'
      client[datastream_url(pid, dsid, options)].get
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
      client[datastream_url(pid, dsid, options)].put nil
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
      client[url_for(datastream_url(pid, dsid) + "/versions", options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_dissemination options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      raise "" unless dsid
      client[url_for(datastream_url(pid, dsid) + "/content", options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def add_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:file)
      content_type = options.delete(:content_type) || options[:mimeType] || (MIME::Types.type_for(file.path).first if file.respond_to? :path) || 'text/plain'
      client[datastream_url(pid, dsid, options)].post file, :content_type => content_type.to_s
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def modify_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:file)
      content_type = options.delete(:content_type) || options[:mimeType] || (MIME::Types.type_for(file.path).first if file.respond_to? :path) || 'text/plain'
      client[datastream_url(pid, dsid, options)].put file, :content_type => content_type.to_s
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def purge_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      client[datastream_url(pid, dsid, options)].delete
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def relationships options = {}
      pid = options.delete(:pid) || options[:subject]
      raise "" unless pid
      options[:format] ||= 'xml'
      client[url_for(object_url(pid) + "/relationships", options)].get
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def add_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      client[url_for(object_url(pid) + "/relationships/new", options)].post nil
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      client[url_for(object_url(pid) + "/relationships", options)].delete
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :sdef
    # @option options [String] :method
    # @return [String]
    def dissemination options = {}
      pid = options.delete(:pid)
      sdef = options.delete(:sdef)
      method = options.delete(:method)
      options[:format] ||= 'xml' unless pid and sdef and method
      client[dissemination_url(pid,sdef,method,options)].get
    end
    
    # Generate a REST API compatible URI 
    # @param [String] base base URI
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def url_for base, options = nil
      return base unless options.is_a? Hash
      "#{base}" + (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')
    end

    # Generate a base object REST API endpoint URI
    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def object_url pid = nil, options = nil
      url_for("objects" + (("/#{CGI::escape(pid.to_s.gsub('info:fedora/', ''))}" if pid) || ''), options)
    end

    # Generate a base object dissemination REST API endpoint URI
    # @param [String] pid
    # @param [String] sdef
    # @param [String] method
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def dissemination_url pid, sdef = nil, method = nil, options = nil
      raise "" unless pid
      url_for(object_url(pid) + "/methods" +  (("/#{CGI::escape(sdef)}" if sdef) || '') +  (("/#{CGI::escape(method)}" if method) || ''), options)
    end

    # Generate a base datastream REST API endpoint URI
    # @param [String] pid
    # @param [String] dsid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def datastream_url pid, dsid = nil, options = nil
      raise "" unless pid
      url_for(object_url(pid) + "/datastreams" + (("/#{CGI::escape(dsid)}" if dsid) || ''), options)
    end

  end
end
