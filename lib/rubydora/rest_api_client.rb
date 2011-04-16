module Rubydora
  module RestApiClient
    def client config = {}
      config = @config.merge(config)
      @client ||= RestClient::Resource.new @config[:url], :user => @config[:user], :password => @config[:password]
    end

    def next_pid options = {}
      client[url_for(object_url() + "/nextPID", options)].post nil
    end

    def find_objects options = {}
      raise "" if options[:terms] and options[:query]

      client[object_url(nil, options)].get
    end

    def object options = {}
      pid = options.delete(:pid)
      client[object_url(pid, options)].get
    end

    def ingest options = {}
      pid = options.delete(:pid) || 'new'
      file = options.delete(:file)
      client[object_url(pid, options)].post file, :content_type => 'text/xml'
    end

    def modify_object options = {}
      pid = options.delete(:pid)
      client[object_url(pid, options)].put nil
    end

    def purge_object options = {}
      pid = options.delete(:pid)
      client[object_url(pid, options)].delete
    end

    def object_versions options = {}
      pid = options.delete(:pid)
      raise "" unless pid
      client[url_for(object_url(pid) + "/versions", options)].get
    end

    def object_xml options = {}
      pid = options.delete(:pid)
      raise "" unless pid
      client[url_for(object_url(pid) + "/objectXML", options)].get
    end

    def datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      client[datastream_url(pid, dsid, options)].get
    end

    alias_method :datastreams, :datastream

    def set_datastream_options options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      client[datastream_url(pid, dsid, options)].put nil
    end

    def datastream_versions options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      raise "" unless dsid
      client[url_for(datastream_url(pid, dsid) + "/versions", options)].get
    end

    def datastream_dissemination options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      options[:format] ||= false
      raise "" unless dsid
      client[url_for(datastream_url(pid, dsid) + "/content", options)].get
    end

    def add_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:file)
      content_type = options.delete(:content_type) || options[:mimeType] || 'text/plain'
      client[datastream_url(pid, dsid, options)].post file, :content_type => content_type
    end

    def modify_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:file)
      content_type = options.delete(:content_type) || options[:mimeType] || 'text/plain'
      client[datastream_url(pid, dsid, options)].put file, :content_type => content_type
    end

    def purge_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      client[datastream_url(pid, dsid, options)].delete
    end

    def relationships options = {}
      pid = options.delete(:pid)
      raise "" unless pid
      client[url_for(object_url(pid) + "/relationships", options)].get
    end

    def add_relationship options = {}
      pid = options.delete(:pid)
      client[url_for(object_url(pid) + "/relationships", options)].post nil
    end

    def purge_relationship options = {}
      pid = options.delete(:pid)
      client[url_for(object_url(pid) + "/relationships", options)].delete
    end


    def dissemination options = {}
      pid = options.delete(:pid)
      sdef = options.delete(:sdef)
      method = options.delete(:method)
      client[dissemination_url(pid,sdef,method,options)].get
    end
    
    private

    def url_for base, options = nil
      return base unless options.is_a? Hash

      options[:format] ||= 'xml' unless options[:format] == false
      options.delete(:format) unless options[:format]
      "#{base}" + (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')
    end

    def object_url pid = nil, options = nil
      url_for("objects" + (("/#{CGI::escape(pid)}" if pid) || ''), options)
    end

    def dissemination_url pid, sdef = nil, method = nil, options = nil
      raise "" unless pid
      url_for(object_url(pid) + "/methods" +  (("/#{CGI::escape(sdef)}" if sdef) || '') +  (("/#{CGI::escape(method)}" if method) || ''), options)
    end

    def datastream_url pid, dsid = nil, options = nil
      raise "" unless pid
      url_for(object_url(pid) + "/datastreams" + (("/#{CGI::escape(dsid)}" if dsid) || ''), options)
    end

  end
end
