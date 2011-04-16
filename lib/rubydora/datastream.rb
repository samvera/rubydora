module Rubydora
  module Datastream
    def self.new digital_object, dsid, dsxml = nil
      ds = Base.new digital_object, dsid
      ds.profile = dsxml
      ds
    end

    class Base
      attr_reader :dsid

      def initialize digital_object, dsid
        @digital_object = digital_object
        @dsid = dsid
      end

      def new!
        @new = true
      end
      
      def new?
        @new
      end


      def profile
        @profile ||= begin
          profile = nil
                     end
      end

      def profile= xml
        @profile = xml
      end

      def dirty?
        false
      end

      def save
        return create if new?
      end

      protected

      def client
        @digital_object.send(:client)["datastreams/%s"%[dsid]]
      end
    end
  end
end
