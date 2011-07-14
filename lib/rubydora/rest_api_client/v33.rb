module Rubydora::RestApiClient
  # Fall-back implementations for fcrepo < 3.4
  module V33
    # @param [Rubydora::Repository] repository
    def self.extended repository
      repository.send(:extend, Rubydora::Soap)
    end

    # {include:RestApiClient#relationships}
    def relationships options = {}
      nil
    end

    # {include:RestApiClient#add_relationship}
    def add_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      self.soap.request :add_relationship, :pid => pid, :relationship => options[:predicate], :object => options[:object], :isLiteral => false, :datatype => nil
    end

    # {include:RestApiClient#purge_relationship}
    def purge_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      self.soap.request :purge_relationship, :pid => pid, :relationship => options[:predicate], :object => options[:object], :isLiteral => false, :datatype => nil
    end

  end
end
