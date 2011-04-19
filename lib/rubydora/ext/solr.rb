module Rubydora::Ext
  # Mapping Fedora objects to Solr documents
  module Solr
    # load this module by mixing into appropriate modules
    # @param [Hash] args
    # @option args [Class] :digital_object
    # @option args [Class] :datastream
    def self.load args = { :digital_object => Rubydora::DigitalObject, :datastream => Rubydora::Datastream}
      args[:digital_object].send(:include, Rubydora::Ext::Solr::DigitalObjectMixin) if args[:digital_object]
      args[:datastream].send(:include, Rubydora::Ext::Solr::DatastreamMixin) if args[:datastream]
    end

    # Datastreams mixin
    module DatastreamMixin
      # Initialize solr mapping logic
      # @param [Class] base
      def self.included(base)
        base.instance_eval %Q{
          class << self; attr_accessor :solr_mapping_logic end
        }  

        base.class_eval %Q{
          attr_writer :solr_mapping_logic
          def solr_mapping_logic
            @solr_mapping_logic ||= self.class.solr_mapping_logic.dup
          end
        }

        base.solr_mapping_logic ||= []
      end

      # sets appropriate solr document parameters for this datastream
      # @param [Hash] doc Solr document object (pass-by-reference)
      def to_solr(doc = {})
      end

    end

    # DigitalObject mixin
    module DigitalObjectMixin
      # Initialize solr mapping logic
      # @param [Class] base 
      def self.included(base)
        base.instance_eval %Q{
          class << self; attr_accessor :solr_mapping_logic end
        }  

        base.class_eval %Q{
          attr_writer :solr_mapping_logic
          def solr_mapping_logic
            @solr_mapping_logic ||= self.class.solr_mapping_logic.dup
          end
        }

        base.solr_mapping_logic ||= [:object_profile_to_solr,:datastreams_to_solr, :relations_to_solr]
      end

      ##
      # Set appropriate solr document attributes for this object
      # @param [Hash] doc Solr document object (pass-by-reference)
      def to_solr(doc = {})
        self.solr_mapping_logic.each do |method_name|
          send(method_name, doc)
        end

        doc.reject { |k,v| v.nil? or (v.respond_to?(:empty?) and v.empty?) }
      end

      # add solr document attributes from the object profile
      # @param [Hash] doc Solr document object (pass-by-reference)
      def object_profile_to_solr doc
        doc['id'] = pid
        doc['pid_s'] = pid

        self.profile.each do |key, value|
          doc["#{key}_s"] = value
        end
      end

      # add solr document attributes from the object datastreams
      # @param [Hash] doc Solr document object (pass-by-reference)
      def datastreams_to_solr doc
        datastreams.each do |dsid, ds|
          doc['disseminates_s'] ||= []
          doc['disseminates_s'] << [dsid]
          ds.to_solr(doc)
        end
      end

      # add solr document attributes by querying the resource index
      # @param [Hash] doc Solr document object (pass-by-reference)
      def relations_to_solr doc
        self.repository.sparql("SELECT ?relation ?object FROM <#ri> WHERE {
   <#{uri}> ?relation ?object
}").each do |row|
          solr_field = "ri_#{row['relation'].split('#').last}_s"
          doc[solr_field] ||= []
          doc[solr_field] << row['object']
        end
      end
    end
  end
end
