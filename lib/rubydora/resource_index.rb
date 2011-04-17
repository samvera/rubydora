module Rubydora
  module ResourceIndex
    # Find new objects using a sparql query
    # @param [String] query SPARQL query
    # @param [Hash] options 
    # @option options [String] :binding the SPARQL binding name to create new objects from
    # @return [Array<Rubydora::DigitalObject>]
    def find_by_sparql query, options = { :binding => 'pid' }
      self.sparql(query).map { |x| self.find(x[options[:binding]]) rescue nil }
    end

    # Find new objects by their relationship to a subject
    # @param [String] subject Subject URI 
    # @param [String] predicate Predicate URI
    # @return [Array<Rubydora::DigitalObject>]
    def find_by_sparql_relationship subject, predicate
      find_by_sparql <<-RELSEXT
        SELECT ?pid FROM <#ri> WHERE {
          #{subject} #{predicate} ?pid 
        }
      RELSEXT
    end

    # Run a raw SPARQL query and return a FasterCSV object
    # @param [String] query SPARQL query
    # @return [FasterCSV::Table]
    def sparql query
      FasterCSV.parse(self.risearch(query), :headers => true)
    end

    protected
    # Run a raw query against the Fedora risearch resource index
    # @param [String] query
    # @param [Hash] options
    def risearch query, options = {}
      request_params = { :dt => 'on', :format => 'CSV', :lang => 'sparql', :limit => nil, :query => query, type => 'tuples' }.merge(options)

      self.client['risearch'].post request_params
    end

  end
end
