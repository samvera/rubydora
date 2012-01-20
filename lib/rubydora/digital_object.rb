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

    OBJ_DEFAULT_ATTRIBUTES = { }

    define_attribute_methods OBJ_ATTRIBUTES.keys
      
    OBJ_ATTRIBUTES.each do |attribute, profile_name|
      class_eval <<-RUBY
      def #{attribute.to_s}
        @#{attribute} || profile['#{profile_name.to_s}'] || OBJ_DEFAULT_ATTRIBUTES[:#{attribute}]
      end

      def #{attribute.to_s}= val
        #{attribute.to_s}_will_change! unless val == #{attribute.to_s}
        @#{attribute.to_s} = val
      end
      RUBY
    end

    # find an existing fedora object
    # TODO: raise an error if the object does not yet exist
    # @param [String] pid
    # @param [Rubydora::Repository] context
    def self.find pid, repository = nil, options = {}
      self.new pid, repository, options
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
        @options = options

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

    def asOfDateTime asOfDateTime = nil
      if asOfDateTime == nil
        return @asOfDateTime
      end

      return self.class.new(pid, @repository, @options.merge(:asOfDateTime => asOfDateTime))
    end

    def asOfDateTime= val
      @asOfDateTime = val
    end

    # Retrieve the object profile as a hash (and cache it)
    # @return [Hash] see Fedora #getObject documentation for keys
    def profile
      @profile ||= begin
        options = { :pid => pid }
        options[:asOfDateTime] = asOfDateTime if asOfDateTime
        profile_xml = repository.object(options)
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
      end.freeze
    end

    def versions
      versions_xml = repository.object_versions(:pid => pid)
      versions_xml.gsub! '<fedoraObjectHistory', '<fedoraObjectHistory xmlns="http://www.fedora.info/definitions/1/0/access/"' unless versions_xml =~ /xmlns=/
      doc = Nokogiri::XML(versions_xml)
      doc.xpath('//access:objectChangeDate', {'access' => 'http://www.fedora.info/definitions/1/0/access/' } ).map do |changeDate|
        self.class.new pid, repository, :asOfDateTime => changeDate.text 
      end
    end


    # List of datastreams
    # @return [Array<Rubydora::Datastream>] 
    def datastreams
      @datastreams ||= begin
        h = Hash.new { |h,k| h[k] = datastream_object_for(k) }                

        begin
          options = { :pid => pid }
          options[:asOfDateTime] = asOfDateTime if asOfDateTime
          datastreams_xml = repository.datastreams(options)
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
      check_if_read_only
      run_callbacks :save do
        if self.new?
          self.pid = repository.ingest to_api_params.merge(:pid => pid)
          @profile = nil #will cause a reload with updated data
        else                       
          p = to_api_params
          repository.modify_object p.merge(:pid => pid) unless p.empty?
        end
      end

      self.datastreams.select { |dsid, ds| ds.changed? }.each { |dsid, ds| ds.save }
      self
    end

    # Purge the object from Fedora
    # @return [Rubydora::DigitalObject] `self`
    def delete
      check_if_read_only
      my_pid = pid
      run_callbacks :destroy do
        @datastreams = nil
        @profile = nil
        @pid = nil
        nil
      end
      repository.purge_object(:pid => my_pid) ##This can have a meaningful exception, don't put it in the callback
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
      OBJ_DEFAULT_ATTRIBUTES.dup
    end

    # instantiate a datastream object for a dsid
    # @param [String] dsid
    # @return [Datastream]
    def datastream_object_for dsid, options = {}
      options[:asOfDateTime] ||= asOfDateTime if asOfDateTime
      Datastream.new self, dsid, options
    end

    def check_if_read_only
      raise "Can't change values on older versions" if @asOfDateTime
    end

    def check_if_read_only
      raise "Can't change values on older versions" if @asOfDateTime
    end

    private
    def attribute_will_change! *args
      check_if_read_only
      super
    end

  end
end
