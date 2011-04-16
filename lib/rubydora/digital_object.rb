module Rubydora
  class DigitalObject
    class << self
      include Rubydora::Callbacks
    end
    include Rubydora::ExtensionParameters
    include Rubydora::ModelsMixin
    include Rubydora::RelationshipsMixin

    attr_reader :pid
    OBJ_ATTRIBUTES = {:state => :objState, :ownerId => :objOwnerId, :label => :objLabel, :logMessage => nil, :lastModifiedDate => :objLastModDate }
      
    OBJ_ATTRIBUTES.each do |attribute, profile_name|
      class_eval <<-RUBY
      def #{attribute.to_s}
        @#{attribute.to_s} || profile['#{profile_name.to_s}']
      end

      attr_writer :#{attribute.to_s}

      RUBY
    end

    def self.find pid, repository = nil
      DigitalObject.new pid, repository
    end

    def self.create pid, options = {}, repository = nil
      repository ||= Rubydora.repository

      repository.ingest(options.merge(:pid => pid))

      DigitalObject.new pid, repository
    end


    def initialize pid, repository = nil, options = {}
      @pid = pid
      @repository = repository

      options.each do |key, value|
        self.send(:"#{key}=", value)
      end

      self.class.hooks.each do |h|
        instance_eval &h
      end
    end

    def fqpid
      return pid if pid =~ /.+\/.+/
      "info:fedora/#{pid}"
    end

    def delete
      repository.purge_object(:pid => pid)
    end

    def new?
      self.profile.nil?
    end

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
          h[key] = value.first
        end

        h
      rescue  
        nil
      end
    end

    def datastreams
      @datastreams ||= begin
        h = Hash.new { |h,k| h[k] = Datastream.new self, k }                
        datastreams_xml = repository.datastreams(:pid => pid)
        datastreams_xml.gsub! '<objectDatastreams', '<objectDatastreams xmlns="http://www.fedora.info/definitions/1/0/access/"' unless datastreams_xml =~ /xmlns=/
        doc = Nokogiri::XML(datastreams_xml)
        doc.xpath('//access:datastream', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).each { |ds| h[ds['dsid']] = Datastream.new self, ds['dsid'] }
        h
      end
    end

    def save
      if self.new?
        repository.ingest to_api_params.merge(:pid => pid)
      else                       
        p = to_api_params
        repository.modify_object p.merge(:pid => pid) unless p.empty?
      end

      self.datastreams.select { |dsid, ds| ds.dirty? }.reject {|dsid, ds| ds.empty? }.each { |dsid, ds| ds.save }
    end


    protected
    def to_api_params
      h = default_api_params
      OBJ_ATTRIBUTES.each do |attribute, profile_name|
        h[attribute] = instance_variable_get("@#{attribute.to_s}") if instance_variable_defined?("@#{attribute.to_s}")
      end

      h
    end

    def default_api_params
      { }
    end

    def repository
      @repository ||= Rubydora.repository
    end

  end
end
