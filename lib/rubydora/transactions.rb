module Rubydora
  
  module Transactions
    extend ActiveSupport::Concern

    class << self
      attr_accessor :use_transactions
    end

    included do
      after_ingest do |options|
        append_to_transactions_log :ingest, options if Rubydora::Transactions.use_transactions
      end

      before_purge_object do |options|
        append_to_transactions_log :purge_object, :pid => options[:pid], :foxml => export(:pid => options[:pid], :context => :archive) if Rubydora::Transactions.use_transactions
      end

      before_modify_datastream do |options|
        append_to_transactions_log :modify_datastream, :pid => options[:pid], :foxml => export(:pid => options[:pid], :context => :archive) if Rubydora::Transactions.use_transactions
      end

      before_purge_datastream do |options|
        append_to_transactions_log :purge_datastream, :pid => options[:pid], :foxml => export(:pid => options[:pid], :context => :archive) if Rubydora::Transactions.use_transactions
      end

      before_add_datastream do |options|
        append_to_transactions_log :add_datastream, options if Rubydora::Transactions.use_transactions
      end

      before_add_relationship do |options|
        append_to_transactions_log :add_relationship, options if Rubydora::Transactions.use_transactions
      end

      before_purge_relationship do |options|
        append_to_transactions_log :purge_relationship, options if Rubydora::Transactions.use_transactions
      end

      before_modify_object do |options|
        if Rubydora::Transactions.use_transactions
          obj = find(options[:pid])
          append_to_transactions_log :modify_object, :pid => options[:pid], :state => obj.state, :ownerId => obj.ownerId, :logMessage => 'reverting'
        end
      end

      before_set_datastream_options do |options|
        if Rubydora::Transactions.use_transactions
          obj = find(options[:pid])
          ds = obj.datastreams[options[:dsid]]

          if options[:options][:versionable]
            append_to_transactions_log :set_datastream_options, :pid => options[:pid], :dsid => options[:dsid], :versionable => ds.versionable
          end

          if options[:options][:state]
            append_to_transactions_log :set_datastream_options, :pid => options[:pid], :dsid => options[:dsid], :state => ds.state
          end
        end
      end

    end
    

    def transaction &block
      Transaction.new self, &block
    end

    def append_to_transactions_log *args
      return unless Rubydora::Transactions.use_transactions
      transactions_log.unshift(args)
    end

    def transactions_log
      @log ||= []
    end
  end

  class Transaction
    attr_reader :repository
    def initialize repository, &block
      @repository = repository
      @old_state = Rubydora::Transactions.use_transactions
      Rubydora::Transactions.use_transactions = true
      yield(self)
      Rubydora::Transactions.use_transactions = @old_state
      repository.transactions_log.clear
    end

    def rollback
      old_state = Rubydora::Transactions.use_transactions
      Rubydora::Transactions.use_transactions = false 

      repository.transactions_log.delete_if do |(method, options)|

        begin
        case method
          when :ingest
            repository.purge_object :pid => options[:pid]

          when :modify_object
            repository.modify_object options

          when :add_datastream
            repository.purge_datastream :pid => options[:pid], :dsid => options[:dsid]

          when :add_relationship
            repository.purge_relationship options[:options].merge(:pid => options[:pid])

          when :purge_relationship
            repository.add_relationship options[:options].merge(:pid => options[:pid])

          when :purge_object
            repository.ingest :pid => options[:pid], :file => options[:foxml]

          when :set_datastream_options
            repository.set_datastream_options options

          when :modify_datastream
            repository.purge_object :pid => options[:pid] rescue nil
            repository.ingest :pid => options[:pid], :file => options[:foxml]

          when :purge_datastream
            repository.purge_object :pid => options[:pid] rescue nil
            repository.ingest :pid => options[:pid], :file => options[:foxml]
        end
        rescue
        end
      true
      end
      Rubydora::Transactions.use_transactions = old_state
    end
  end

end
