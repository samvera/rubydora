module Rubydora
  # This class represents a Fedora datastream object
  # and provides helper methods for creating and manipulating
  # them. 
  class Datastream
    extend ActiveModel::Callbacks
    define_model_callbacks :initialize, :only => :after

    include ActiveModel::Dirty

    include Rubydora::ExtensionParameters

    attr_reader :digital_object, :dsid

    # mapping datastream attributes (and api parameters) to datastream profile names
    DS_ATTRIBUTES = {:controlGroup => :dsControlGroup, :dsLocation => :dsLocation, :altIDs => nil, :dsLabel => :dsLabel, :versionable => :dsVersionable, :dsState => :dsState, :formatURI => :dsFormatURI, :checksumType => :dsChecksumType, :checksum => :dsChecksum, :mimeType => :dsMIME, :logMessage => nil, :ignoreContent => nil, :lastModifiedDate => nil, :file => nil}

    define_attribute_methods DS_ATTRIBUTES.keys + [:content]
    
    # accessors for datastream attributes 
    DS_ATTRIBUTES.each do |attribute, profile_name|
      class_eval %Q{
      def #{attribute.to_s}
        (@#{attribute} || profile['#{profile_name.to_s}']).to_s
      end

      def #{attribute.to_s}= val
        #{attribute.to_s}_will_change! unless val == @#{attribute.to_s}
        @#{attribute.to_s} = val
      end
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
    # @param [Hash] default attribute values (used esp. for creating new datastreams)
    def initialize digital_object, dsid, options = {}
      _run_initialize_callbacks do
      @digital_object = digital_object
      @dsid = dsid
      options.each do |key, value|
        self.send(:"#{key}=", value)
      end
      end
    end

    # Helper method to get digital object pid
    def pid
      digital_object.pid
    end

    # Does this datastream already exist?
    # @return [Boolean]
    def new?
      profile.empty?
    end

    # Retrieve the content of the datastream (and cache it)
    # @return [String]
    def content
      begin
        @content ||= repository.datastream_dissemination :pid => pid, :dsid => dsid
      rescue RestClient::ResourceNotFound
      end
    end
    alias_method :read, :content

    # Get the URL for the datastream content
    # @return [String]
    def url
      repository.datastream_url(pid, dsid) + "/content"
    end

    # Set the content of the datastream
    # @param [String or IO] 
    # @return [String or IO]
    def content= content
       content_will_change!
       @file = content
       @content = content.dup
       @content &&= @content.read if @content.respond_to? :read
       @content &&= @content.to_s if @content.respond_to? :read
    end

    # Retrieve the datastream profile as a hash (and cache it)
    # @return [Hash] see Fedora #getDatastream documentation for keys
    def profile
      @profile ||= begin
        profile_xml = repository.datastream(:pid => pid, :dsid => dsid)
        profile_xml.gsub! '<datastreamProfile', '<datastreamProfile xmlns="http://www.fedora.info/definitions/1/0/management/"' unless profile_xml =~ /xmlns=/
        doc = Nokogiri::XML(profile_xml)
        h = doc.xpath('/management:datastreamProfile/*', {'management' => "http://www.fedora.info/definitions/1/0/management/"} ).inject({}) do |sum, node|
                     sum[node.name] ||= []
                     sum[node.name] << node.text
                     sum
                   end
        h.select { |key, value| value.length == 1 }.each do |key, value|
          h[key] = value.first
        end

        h
      rescue
        {}
      end
    end

    # Add datastream to Fedora
    # @return [Rubydora::Datastream]
    def create
      repository.add_datastream to_api_params.merge({ :pid => pid, :dsid => dsid })
      reset_profile_attributes
      Datastream.new(digital_object, dsid)
    end

    # Modify or save the datastream
    # @return [Rubydora::Datastream]
    def save
      return create if new?
      repository.modify_datastream to_api_params.merge({ :pid => pid, :dsid => dsid })
      reset_profile_attributes
      Datastream.new(digital_object, dsid)
    end

    # Purge the datastream from Fedora
    # @return [Rubydora::Datastream] `self`
    def delete
      repository.purge_datastream(:pid => pid, :dsid => dsid) unless self.new?
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
      @changed_attributes = {}
    end

    # repository reference from the digital object
    # @return [Rubydora::Repository]
    def repository
      digital_object.repository
    end
  end
end
