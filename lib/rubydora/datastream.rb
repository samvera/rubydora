module Rubydora
  class Datastream
    include Rubydora::Callbacks
    register_callback :after_initialize
    include Rubydora::ExtensionParameters


    attr_reader :digital_object, :dsid
                                                                   
    DS_ATTRIBUTES = {:controlGroup => :dsControlGroup, :dsLocation => :dsLocation, :altIDs => nil, :dsLabel => :dsLabel, :versionable => :dsVersionable, :dsState => :dsState, :formatURI => :dsFormatURI, :checksumType => :dsChecksumType, :checksum => :dsChecksum, :mimeType => :dsMIME, :logMessage => nil, :ignoreContent => nil, :lastModifiedDate => nil}
    
    DS_ATTRIBUTES.each do |attribute, profile_name|
      class_eval <<-RUBY
      def #{attribute.to_s}
        @#{attribute.to_s} || profile['#{profile_name.to_s}']
      end

      attr_writer :#{attribute.to_s}

      RUBY
    end

    def initialize digital_object, dsid, options = {}
      @digital_object = digital_object
      @dsid = dsid
      options.each do |key, value|
        self.send(:"#{key}=", value)
      end

      call_after_initialize
    end

    def new?
      profile.nil?
    end

    def content
      @content ||= repository.datastream_dissemination :pid => digital_object.pid, :dsid => dsid
    end

    def profile
      @profile ||= begin
        profile_xml = repository.datastream(:pid => digital_object.pid, :dsid => dsid)
        profile_xml.gsub! '<datastreamProfile', '<datastreamProfile xmlns="http://www.fedora.info/definitions/1/0/access/"' unless profile_xml =~ /xmlns=/
        doc = Nokogiri::XML(profile_xml)
        h = doc.xpath('/access:datastreamProfile/*', {'access' => "http://www.fedora.info/definitions/1/0/access/"} ).inject({}) do |sum, node|
                     sum[node.name] ||= []
                     sum[node.name] << node.text
                     sum
                   end
        h.select { |key, value| value.length == 1 }.each do |key, value|
          h[key] = value.first
        end

        h
      rescue
         nil
      end
    end

    def dirty?
      DS_ATTRIBUTES.any? { |attribute, profile_name| instance_variable_defined?("@#{attribute.to_s}") } || new?
    end

    def create
      repository.add_datastream to_api_params.merge({ :pid => digital_object.pid, :dsid => dsid })
    end

    def save
      return create if new?
      repository.modify_datastream to_api_params.merge({ :pid => digital_object.pid, :dsid => dsid })
    end

    def delete
      repository.purge_datastream(:pid => digital_object.pid, :dsid => dsid) unless self.new?
    end

    protected
    def to_api_params
      h = default_api_params
      DS_ATTRIBUTES.each do |attribute, profile_name|
        h[attribute] = instance_variable_get("@#{attribute.to_s}") if instance_variable_defined?("@#{attribute.to_s}")
      end

      h
    end

    def default_api_params
      { :controlGroup => 'M', :dsState => 'A', :checksumType => 'NONE', :versionable => true}
    end

    def repository
      digital_object.repository
    end
  end
end
