module Rubydora
  module ProfileParser
    def self.parse_datastream_profile profile_xml
      profile_xml.gsub! '<datastreamProfile', '<datastreamProfile xmlns="http://www.fedora.info/definitions/1/0/management/"' unless profile_xml =~ /xmlns=/
      doc = Nokogiri::XML(profile_xml)
      h = doc.xpath('/management:datastreamProfile/*', {'management' => "http://www.fedora.info/definitions/1/0/management/"} ).inject({}) do |sum, node|
                   sum[node.name] ||= []
                   sum[node.name] << node.text
                   sum
                 end.reject { |key, values| values.empty? }
      h.select { |key, values| values.length == 1 }.each do |key, values|
        h[key] = values.reject { |x| x.empty? }.first 
      end

      h['dsSize'] &&= h['dsSize'].to_i rescue h['dsSize']
      h['dsCreateDate'] &&= Time.parse(h['dsCreateDate']) rescue h['dsCreateDate']
      h['dsChecksumValid'] &&= h['dsChecksumValid'] == 'true' 
      h['dsVersionable'] &&= h['dsVersionable'] == 'true' 
      h.with_indifferent_access
    end

    def self.parse_object_profile profile_xml
      profile_xml.gsub! '<objectProfile', '<objectProfile xmlns="http://www.fedora.info/definitions/1/0/access/"' unless profile_xml =~ /xmlns=/
      doc = Nokogiri::XML(profile_xml)
      h = doc.xpath('/access:objectProfile/*', {'access' => "http://www.fedora.info/definitions/1/0/access/"} ).inject({}) do |sum, node|
                   sum[node.name] ||= []
                   sum[node.name] << node.text

                   if node.name == "objModels"
                     sum[node.name] = node.xpath('access:model', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).map { |x| x.text }
                   end

                   sum
                 end.reject { |key, values| values.empty? }
      h.select { |key, values| values.length == 1 }.each do |key, values|
        next if key == "objModels"
        h[key] = values.reject { |x| x.empty? }.first
      end
      h.with_indifferent_access
    end

    def self.parse_repository_profile profile_xml
      profile_xml.gsub! '<fedoraRepository', '<fedoraRepository xmlns="http://www.fedora.info/definitions/1/0/access/"' unless profile_xml =~ /xmlns=/
      doc = Nokogiri::XML(profile_xml)
      xmlns = { 'access' => "http://www.fedora.info/definitions/1/0/access/"  }
      h = doc.xpath('/access:fedoraRepository/*', xmlns).inject({}) do |sum, node|
                   sum[node.name] ||= []
                   case node.name
                     when "repositoryPID"
                       sum[node.name] << Hash[*node.xpath('access:*', xmlns).map { |x| [node.name, node.text]}.flatten]
                     else
                       sum[node.name] << node.text
                   end
                   sum
                 end
      h.with_indifferent_access
    end
  end
end
