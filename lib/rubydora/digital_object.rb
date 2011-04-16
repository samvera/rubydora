module Rubydora
  module DigitalObject
    def self.find pid, repository = nil
      Base.new pid, repository
    end

    def self.create pid, options = {}, repository = nil
      repository ||= Rubydora.repository

      repository.ingest(options.merge(:pid => pid))

      Base.new pid, repository
    end

    class Base
      attr_reader :pid

      def initialize pid, repository = nil
        @pid = pid
        @repository = repository
      end

      def delete
        repository.purge_object(:pid => pid)
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

        end
      end

      def datastreams
        @datastreams ||= begin
          h = Hash.new { |h,k| h[k] = Datastream.new self, k; h[k].new!; h[k] }                
          datastreams_xml = repository.datastreams(:pid => pid)
          datastreams_xml.gsub! '<objectDatastreams', '<objectDatastreams xmlns="http://www.fedora.info/definitions/1/0/access/"' unless datastreams_xml =~ /xmlns=/
          doc = Nokogiri::XML(datastreams_xml)
          doc.xpath('//access:datastream', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).each { |ds| h[ds['dsid']] = Datastream.new self, ds['dsid'], ds.to_s }
          h
        end
      end

      def save
        self.datastreams.select(&:dirty?).reject(&:empty?).each(&:save)
      end


      protected

      def repository
        @repository ||= Rubydora.repository
      end

    end

  end
end
