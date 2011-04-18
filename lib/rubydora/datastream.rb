module Rubydora
  # This class represents a Fedora datastream object
  # and provides helper methods for creating and manipulating
  # them. 
  class Datastream
    include Rubydora::Callbacks
    register_callback :after_initialize
    include Rubydora::ExtensionParameters

    attr_reader :digital_object, :dsid

    # mapping datastream attributes (and api parameters) to datastream profile names
    DS_ATTRIBUTES = {:controlGroup => :dsControlGroup, :dsLocation => :dsLocation, :altIDs => nil, :dsLabel => :dsLabel, :versionable => :dsVersionable, :dsState => :dsState, :formatURI => :dsFormatURI, :checksumType => :dsChecksumType, :checksum => :dsChecksum, :mimeType => :dsMIME, :logMessage => nil, :ignoreContent => nil, :lastModifiedDate => nil, :file => nil}
    
    # accessors for datastream attributes 
    DS_ATTRIBUTES.each do |attribute, profile_name|
      class_eval %Q{
        def #{attribute.to_s}
          @#{attribute.to_s} || profile['#{profile_name.to_s}']
        end

        attr_writer :#{attribute.to_s}
      }
    end

    ##
    # Initialize a Rubydora::Datastream object, which may or
    # may not already exist in the datastore.
    #
    # Provides `after_initialize` callback for extensions
    # 
    # @param [Rubydora::DigitalObject]
    # @param [String] Datastream ID
    # @param [Hash] default attribute values (used esp. for creating new datastreams
    def initialize digital_object, dsid, options = {}
      @digital_object = digital_object
      @dsid = dsid
      options.each do |key, value|
        self.send(:"#{key}=", value)
      end

      call_after_initialize
    end

    # Does this datastream already exist?
    # @return [Boolean]
    def new?
      profile.nil?
    end

    # Retrieve the content of the datastream (and cache it)
    # @return [String]
    def content
      @content ||= repository.datastream_dissemination :pid => digital_object.pid, :dsid => dsid
    end
    alias_method :read, :content

    def content= content
       @file = content
       @content = content.dup
       @content &&= @content.read if @content.respond_to? :read
       @content &&= @content.to_s if @content.respond_to? :read
    end

    # Retrieve the datastream profile as a hash (and cache it)
    # @return [Hash] see Fedora #getDatastream documentation for keys
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

    # Has this datastream been modified, but not yet saved?
    # @return [Boolean]
    def dirty?
      DS_ATTRIBUTES.any? { |attribute, profile_name| instance_variable_defined?("@#{attribute.to_s}") } || new?
    end

    # Add datastream to Fedora
    # @return [Rubydora::Datastream]
    def create
      repository.add_datastream to_api_params.merge({ :pid => digital_object.pid, :dsid => dsid })
      reset_profile_attributes
      Datastream.new(digital_object, dsid)
    end

    # Modify or save the datastream
    # @return [Rubydora::Datastream]
    def save
      return create if new?
      repository.modify_datastream to_api_params.merge({ :pid => digital_object.pid, :dsid => dsid })
      reset_profile_attributes
      Datastream.new(digital_object, dsid)
    end

    # Purge the datastream from Fedora
    # @return [Rubydora::Datastream] `self`
    def delete
      repository.purge_datastream(:pid => digital_object.pid, :dsid => dsid) unless self.new?
      digital_object.datastreams.delete(dsid)
      reset_profile_attributes
      self
    end

    protected
    # datastream parameters 
    # @return [Hash]
    def to_api_params
      h = default_api_params
      DS_ATTRIBUTES.each do |attribute, profile_name|
        h[attribute] = instance_variable_get("@#{attribute.to_s}") if instance_variable_defined?("@#{attribute.to_s}")
      end

      h
    end

    # default datastream parameters
    # @return [Hash]
    def default_api_params
      { :controlGroup => 'M', :dsState => 'A', :checksumType => 'DISABLED', :versionable => true}
    end

    # reset all profile attributes
    # @return [Hash]
    def reset_profile_attributes
      @profile = nil
      DS_ATTRIBUTES.each do |attribute, profile_name|
        instance_variable_set("@#{attribute.to_s}", nil) if instance_variable_defined?("@#{attribute.to_s}")
      end
    end

    # repository reference from the digital object
    # @return [Rubydora::Repository]
    def repository
      digital_object.repository
    end
  end
end
