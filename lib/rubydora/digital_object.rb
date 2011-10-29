module Rubydora

  # This class represents a Fedora object and provides
  # helpers for managing attributes, datastreams, and
  # relationships. 
  #
  # Using the extension framework, implementors may 
  # provide additional functionality to this base 
  # implementation.
  class DigitalObject
    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create, :destroy
    define_model_callbacks :initialize, :only => :after
    include ActiveModel::Dirty
    include Rubydora::ExtensionParameters
    include Rubydora::ModelsMixin
    include Rubydora::RelationshipsMixin


    attr_reader :pid
    
    # mapping object parameters to profile elements
    OBJ_ATTRIBUTES = {:state => :objState, :ownerId => :objOwnerId, :label => :objLabel, :logMessage => nil, :lastModifiedDate => :objLastModDate }

    define_attribute_methods OBJ_ATTRIBUTES.keys
      
    OBJ_ATTRIBUTES.each do |attribute, profile_name|
      class_eval <<-RUBY
      def #{attribute.to_s}
        @#{attribute.to_s} || profile['#{profile_name.to_s}']
      end

      def #{attribute.to_s}= val
        #{attribute.to_s}_will_change! unless val == @#{attribute.to_s}
        @#{attribute.to_s} = val
      end
      RUBY
    end

    # find an existing fedora object
    # TODO: raise an error if the object does not yet exist
    # @param [String] pid
    # @param [Rubydora::Repository] context
    def self.find pid, repository = nil
      self.new pid, repository
    end

    # create a new fedora object (see also DigitalObject#save)
    # @param [String] pid
    # @param [Hash] options
    # @param [Rubydora::Repository] context
    def self.create pid, options = {}, repository = nil
      repository ||= Rubydora.repository
      assigned_pid = repository.ingest(options.merge(:pid => pid))

      self.new assigned_pid, repository
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
      _run_initialize_callbacks do
        self.pid = pid
        @repository = repository
        @new = true

        options.each do |key, value|
          self.send(:"#{key}=", value)
        end
      end
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
      self.profile  ### Make sure we've checked the repository at least once
      @new
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
        @new = false

        h
      rescue Exception => e
        {}
      end
    end

    # List of datastreams
    # @return [Array<Rubydora::Datastream>] 
    def datastreams
      @datastreams ||= begin
        h = Hash.new { |h,k| h[k] = datastream_object_for(k) }                

        begin
          datastreams_xml = repository.datastreams(:pid => pid)
          datastreams_xml.gsub! '<objectDatastreams', '<objectDatastreams xmlns="http://www.fedora.info/definitions/1/0/access/"' unless datastreams_xml =~ /xmlns=/
          doc = Nokogiri::XML(datastreams_xml)
          doc.xpath('//access:datastream', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).each do |ds| 
            h[ds['dsid']] = datastream_object_for ds['dsid'] 
          end
        rescue RestClient::ResourceNotFound
        end

        h
      end
    end
    alias_method :datastream, :datastreams

    # provide an hash-like way to access datastreams 
    def fetch dsid
      datastreams[dsid]
    end
    alias_method :[], :fetch

    # persist the object to Fedora, either as a new object 
    # by modifing the existing object
    #
    # also will save all `:dirty?` datastreams that already exist 
    # new datastreams must be directly saved
    # 
    # @return [Rubydora::DigitalObject] a new copy of this object
    def save
      run_callbacks :save do
        if self.new?
          run_callbacks :create do
            self.pid = repository.ingest to_api_params.merge(:pid => pid)
          end
        else                       
          p = to_api_params
          repository.modify_object p.merge(:pid => pid) unless p.empty?
        end
      end

      self.datastreams.select { |dsid, ds| ds.changed? }.each { |dsid, ds| ds.save }
      reset
      self
    end

    # Purge the object from Fedora
    # @return [Rubydora::DigitalObject] `self`
    def delete
      run_callbacks :destroy do
        repository.purge_object(:pid => pid)
        reset
        self
      end
    end

    # repository reference from the digital object
    # @return [Rubydora::Repository]
    def repository
      @repository ||= Rubydora.repository
    end

    protected
    # set the pid of the object
    # @param [String] pid
    # @return [String] the base pid
    def pid= pid=nil
      @pid = pid.gsub('info:fedora/', '') if pid
    end

    # datastream parameters 
    # @return [Hash]
    def to_api_params
      h = default_api_params
      changes.keys.select { |x| OBJ_ATTRIBUTES.key? x.to_sym }.each do |attribute|
        h[attribute.to_sym] = send(attribute) unless send(attribute).nil?
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
      @changed_attributes = {}
    end

    # reset the datastreams cache
    def reset_datastreams
      @datastreams = nil
    end

    # reset local data so that it is requested from Fedora
    def reset
      reset_profile_attributes
      reset_datastreams
      self
    end

    # instantiate a datastream object for a dsid
    # @param [String] dsid
    # @return [Datastream]
    def datastream_object_for dsid
      Datastream.new self, dsid
    end
  end
end
