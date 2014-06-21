module Rubydora
  # This class abstracts away all of the API details including XML parsing
  # This allows the driver (Fc3Service) to be swapped out without having to modify
  # the ORM layer (e.g. Datastream, DigitalObject, Repository)
  class Fc3Service
    include RestApiClient
    include Rubydora::AuditTrail

    attr_reader :config
    def initialize(config)
      @config = config
    end

    # Reserve a new pid for the object
    # @params [Hash] options
    # @option options [String] :namespace the namespece for the pid
    def mint(options={})
      d = Nokogiri::XML(next_pid(options))
      if d.namespaces.values.include? 'http://www.fedora.info/definitions/1/0/management/'
        d.xpath('//fedora:pid', 'fedora' => 'http://www.fedora.info/definitions/1/0/management/').text
      else
        d.xpath('//pid').text
      end
    end


    # repository profile (from API-A-LITE data)
    # @return [Hash]
    def repository_profile
      begin
        profile_xml = self.describe.strip
        h = ProfileParser.parse_repository_profile(profile_xml)
        h.select { |key, value| value.length == 1 }.each do |key, value|
          next if key == "objModels"
          h[key] = value.first
        end

        h
      rescue
        nil
      end
    end

    def object_profile(pid, asOfDateTime = nil)
      options = {pid: pid}
      options[:asOfDateTime] = asOfDateTime if asOfDateTime
      begin 
        xml = object(options)
        ProfileParser.parse_object_profile(xml)
      rescue RestClient::ResourceNotFound
        {}
      end
    end

    def datastream_profile(pid, dsid, validateChecksum, asOfDateTime = nil)
      xml = begin
        options = { pid: pid, dsid: dsid}
        options[:validateChecksum] = validateChecksum if validateChecksum
        options[:asOfDateTime] = asOfDateTime if asOfDateTime
        options[:validateChecksum] = true if config[:validateChecksum]
        datastream(options)
      rescue RestClient::Unauthorized => e
        raise e
      rescue RestClient::ResourceNotFound
        # the datastream is new
        return {}
      end

      ProfileParser.parse_datastream_profile(xml)
    end

    def versions_for_datastream(pid, dsid)
      versions_xml = datastream_versions(:pid => pid, :dsid => dsid)
      return {} if versions_xml.nil?
      versions_xml.gsub! '<datastreamProfile', '<datastreamProfile xmlns="http://www.fedora.info/definitions/1/0/management/"' unless versions_xml =~ /xmlns=/
      doc = Nokogiri::XML(versions_xml)
      versions = {}
      doc.xpath('//management:datastreamProfile', {'management' => "http://www.fedora.info/definitions/1/0/management/"} ).each do |ds|
        key = ds.xpath('management:dsCreateDate', 'management' => "http://www.fedora.info/definitions/1/0/management/").text
        versions[key] = ProfileParser.parse_datastream_profile(ds.to_s)
      end
      versions
    end

    def versions_for_object(pid)
      versions_xml = object_versions(:pid => pid)
      versions_xml.gsub! '<fedoraObjectHistory', '<fedoraObjectHistory xmlns="http://www.fedora.info/definitions/1/0/access/"' unless versions_xml =~ /xmlns=/
      doc = Nokogiri::XML(versions_xml)
      doc.xpath('//access:objectChangeDate', {'access' => 'http://www.fedora.info/definitions/1/0/access/' } ).map(&:text)
    end

  end
end
