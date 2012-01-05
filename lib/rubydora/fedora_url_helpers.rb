module Rubydora
  module FedoraUrlHelpers
    # Fedora API documentation available at {https://wiki.duraspace.org/display/FCR30/REST+API}
    API_DOCUMENTATION = 'https://wiki.duraspace.org/display/FCR30/REST+API'
    
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
    def object_url pid, options = nil
      url_for("objects" + (("/#{CGI::escape(pid.to_s.gsub('info:fedora/', ''))}" if pid) || ''), options)
    end

    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def next_pid_url options = nil
      url_for("objects/nextPID", options)
    end

    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def find_objects_url options = nil
      url_for("objects", options)
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

    # @param [String] pid
    # @param [String] dsid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def datastream_content_url pid, dsid = nil, options = nil
      url_for(datastream_url(pid, dsid) +  "/content", options)
    end

    # @param [String] pid
    # @param [String] dsid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def datastream_history_url pid, dsid = nil, options = nil
      url_for(datastream_url(pid, dsid) +  "/history", options)
    end

    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def validate_object_url pid, options = nil
      url_for(object_url(pid) + "/validate", options)
    end

    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def export_object_url pid, options = nil
      url_for(object_url(pid) + "/export", options)
    end

    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def object_versions_url pid, options = nil
      url_for(object_url(pid) + "/versions", options)
    end

    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def object_xml_url pid, options = nil
      url_for(object_url(pid) + "/objectXML", options)
    end

    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def object_relationship_url pid, options = nil
      url_for(object_url(pid) + "/relationships", options)
    end

    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def new_object_relationship_url pid, options = nil
      url_for(object_relationship_url(pid) + "/new", options)
    end
  end
end
