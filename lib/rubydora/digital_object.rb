module Rubydora

  # This class represents a Fedora object and provides
  # helpers for managing attributes, datastreams, and
  # relationships. 
  #
  # Using the extension framework, implementors may 
  # provide additional functionality to this base 
  # implementation.
  class DigitalObject
    include Rubydora::Callbacks
    register_callback :after_initialize
    include Rubydora::ExtensionParameters
    include Rubydora::ModelsMixin
    include Rubydora::RelationshipsMixin


    attr_reader :pid
    
    # mapping object parameters to profile elements
    OBJ_ATTRIBUTES = {:state => :objState, :ownerId => :objOwnerId, :label => :objLabel, :logMessage => nil, :lastModifiedDate => :objLastModDate }
      
    OBJ_ATTRIBUTES.each do |attribute, profile_name|
      class_eval <<-RUBY
      def #{attribute.to_s}
        @#{attribute.to_s} || profile['#{profile_name.to_s}']
      end
                     
      attr_writer :#{attribute.to_s}

      RUBY
    end

    # find an existing fedora object
    # TODO: raise an error if the object does not yet exist
    # @param [String] pid
    # @param [Rubydora::Repository] context
    def self.find pid, repository = nil
      DigitalObject.new pid, repository
    end

    # create a new fedora object (see also DigitalObject#save)
    # @param [String] pid
    # @param [Hash] options
    # @param [Rubydora::Repository] context
    def self.create pid, options = {}, repository = nil
      repository ||= Rubydora.repository
      repository.ingest(options.merge(:pid => pid))
      DigitalObject.new pid, repository
    end

    ##
    # Initialize a Rubydora::DigitalObject, which may or
    # may not already exist in the data store.
    #
    # Provides `after_initialize` callback for extensions
    # 
    # @param [String] pid
    # @param [Rubydora::Repository] repository context
    # @param [Hash] options default attribute values (used esp. for creating new datastreams
    def initialize pid, repository = nil, options = {}
      @pid = pid.gsub('info:fedora/', '')
      @repository = repository

      options.each do |key, value|
        self.send(:"#{key}=", value)
      end

      call_after_initialize
    end

    ##
    # Return a full uri pid (for use in relations, etc
    def uri
      return pid if pid =~ /.+\/.+/
      "info:fedora/#{pid}"
    end
    alias_method :fqpid, :uri

    # Does this object already exist?
    # @return [Boolean]
    def new?
      self.profile.nil?
    end

    # Retrieve the object profile as a hash (and cache it)
    # @return [Hash] see Fedora #getObject documentation for keys
    def profile
      @profile ||= begin
        profile_xml = repository.object(:pid => pid)
        profile_xml.gsub! '<objectProfile', '<objectProfile xmlns="http://www.fedora.info/definitions/1/0/access/"' unless profile_xml =~ /xmlns=/
        doc = Nokogiri::XML(profile_xml)
        h = doc.xpath('/access:objectProfile/*', {'access' => "http://www.fedora.info/definitions/1/0/access/"} ).inject({}) do |sum, node|
                     sum[node.name] ||= []
                     sum[node.name] << node.text

                     if node.name == "objModels"
                       sum[node.name] = node.xpath('access:model', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).map { |x| x.text }
                     end

                     sum
                   end
        h.select { |key, value| value.length == 1 }.each do |key, value|
          next if key == "objModels"
          h[key] = value.first
        end

        h
      rescue  
        nil
      end
    end

    # List of datastreams
    # @return [Array<Rubydora::Datastream>] 
    def datastreams
      @datastreams ||= begin
        h = Hash.new { |h,k| h[k] = Datastream.new self, k }                
        datastreams_xml = repository.datastreams(:pid => pid)
        datastreams_xml.gsub! '<objectDatastreams', '<objectDatastreams xmlns="http://www.fedora.info/definitions/1/0/access/"' unless datastreams_xml =~ /xmlns=/
        doc = Nokogiri::XML(datastreams_xml)
        doc.xpath('//access:datastream', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).each { |ds| h[ds['dsid']] = Datastream.new self, ds['dsid'] }
        h
      rescue RestClient::ResourceNotFound
        h = Hash.new { |h,k| h[k] = Datastream.new self, k }                
      end
    end
    alias_method :datastream, :datastreams

    def get_datastream dsid
      datastreams[dsid]
    end
    alias_method :[], :get_datastream

    # persist the object to Fedora, either as a new object 
    # by modifing the existing object
    #
    # also will save all `:dirty?` datastreams that already exist 
    # new datastreams must be directly saved
    # 
    # @return [Rubydora::DigitalObject] a new copy of this object
    def save
      if self.new?
        repository.ingest to_api_params.merge(:pid => pid)
      else                       
        p = to_api_params
        repository.modify_object p.merge(:pid => pid) unless p.empty?
      end

      self.datastreams.select { |dsid, ds| ds.dirty? }.reject {|dsid, ds| ds.new? }.each { |dsid, ds| ds.save }
      DigitalObject.new(pid, repository)
    end

    # Purge the object from Fedora
    # @return [Rubydora::DigitalObject] `self`
    def delete
      repository.purge_object(:pid => pid)
      reset_profile_attributes
      self
    end

    # repository reference from the digital object
    # @return [Rubydora::Repository]
    def repository
      @repository ||= Rubydora.repository
    end

    protected
    # datastream parameters 
    # @return [Hash]
    def to_api_params
      h = default_api_params
      OBJ_ATTRIBUTES.each do |attribute, profile_name|
        h[attribute] = instance_variable_get("@#{attribute.to_s}") if instance_variable_defined?("@#{attribute.to_s}")
      end

      h
    end

    # default datastream parameters
    # @return [Hash]
    def default_api_params
      { }
    end

    # reset all profile attributes
    # @return [Hash]
    def reset_profile_attributes
      @profile = nil
      OBJ_ATTRIBUTES.each do |attribute, profile_name|
        instance_variable_set("@#{attribute.to_s}", nil) if instance_variable_defined?("@#{attribute.to_s}")
      end
    end

  end
end
