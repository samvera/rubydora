module Rubydora
  module ProfileParser
    def self.parse_datastream_profile profile_xml
      # since the profile may be in the management or the access namespace, use the CSS selector
      ndoc = Nokogiri::XML(profile_xml)
      doc = (ndoc.name == 'datastreamProfile') ? ndoc : ndoc.css('datastreamProfile').first
      if doc.nil?
        # the datastream is new
        {}.with_indifferent_access
      else
        hash_datastream_profile_node(doc)
      end
    end

    def self.hash_datastream_profile_node doc
      h = doc.xpath('./*').inject({}) do |sum, node|
                   sum[node.name] ||= []
                   sum[node.name] << node.text
                   sum
                 end.reject { |key, values| values.nil? or values.empty? }
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
      h['objLastModDate'] = canonicalize_date_string(h['objLastModDate']) if h['objLastModDate']
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

    # Some versions of Fedora 3 return lexical representations of a w3c date
    # in the object profile, which will not compare correctly to the canonical
    # representations returned from update operations
    def self.canonicalize_date_string(input)
      if input =~ /0Z/
        lmd = input.sub(/\.[0]+Z$/,'Z')
        lmd = lmd.sub(/\.([^0]+)[0]+Z$/,'.\1Z')
        lmd
      else
        input
      end
    end

  end
end
