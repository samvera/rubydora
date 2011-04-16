module Rubydora
  module ResourceIndex
    def find_by_sparql query, options = { :binding => 'pid' }
      self.sparql(query).map { |x| self.find(x[options[:binding]]) rescue nil }
    end

    def sparql query
      FasterCSV.parse(self.risearch(query), :headers => true)
    end

    protected
    def risearch query, options = {}
      request_params = { :dt => 'on', :format => 'CSV', :lang => 'sparql', :limit => nil, :query => query, type => 'tuples' }.merge(options)

      self.client['risearch'].post request_params
    end

  end
end
