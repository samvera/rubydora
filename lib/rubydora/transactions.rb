module Rubydora
  # Extremely basic (and naive) 'transaction' support for Rubydora. This isn't
  # really intended to be used in a production-like situation -- more for
  # rolling back (small) changes during testing.
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
        append_to_transactions_log :purge_object, :pid => options[:pid], :foxml => true if Rubydora::Transactions.use_transactions
      end

      before_modify_datastream do |options|
        append_to_transactions_log :modify_datastream, :pid => options[:pid], :foxml => true if Rubydora::Transactions.use_transactions
      end

      before_purge_datastream do |options|
        append_to_transactions_log :purge_datastream, :pid => options[:pid], :foxml => true if Rubydora::Transactions.use_transactions
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
          xml = object(pid: options[:pid])
          profile = ProfileParser.parse_object_profile(xml)
          append_to_transactions_log :modify_object, :pid => options[:pid], :state => profile[:objState], :ownerId => profile[:objOwnerId], :logMessage => 'reverting'
        end
      end

      before_set_datastream_options do |options|
        if Rubydora::Transactions.use_transactions
          xml = datastream(pid: options[:pid], dsid: options[:dsid])
          profile = ProfileParser.parse_datastream_profile(xml)

          if options[:options][:versionable]
            append_to_transactions_log :set_datastream_options, :pid => options[:pid], :dsid => options[:dsid], :versionable => profile[:dsVersionable]
          end

          if options[:options][:state]
            append_to_transactions_log :set_datastream_options, :pid => options[:pid], :dsid => options[:dsid], :state => profile[:dsState]
          end
        end
      end

    end

    # Start a transaction
    def transaction(&block)
      Transaction.new self, &block
      self.transactions_log.clear
    end

    # Unshift a transaction entry onto the transaction logs.
    # We want these entries in reverse-chronological order
    # for ease of undoing..
    def append_to_transactions_log(method, options = {})
      return unless Rubydora::Transactions.use_transactions
      return if transaction_is_redundant?(method, options)
      options[:foxml] = export(:pid => options[:pid], :context => :archive) if options[:foxml] == true
      transactions_log.unshift([method, options])
    end

    # The repository transaction log.
    def transactions_log
      @log ||= []
    end

    def transaction_is_redundant?(method, options)
      return true if transactions_log.any? { |(t_method, t_options)|
        # these methods will rollback ANY object change that happens after it, so there's no need to track future changes to this object
        t_options[:pid] == options[:pid] && [:ingest, :purge_object, :modify_datastream, :purge_datastream].include?(t_method)
      }
      false
    end
  end

  class Transaction
    attr_reader :repository
    include Hooks
    define_hook :after_rollback

    def initialize(repository, &block)
      @repository = repository
      with_transactions(&block)
    end

    def with_transactions(&block)
      old_state = Rubydora::Transactions.use_transactions
      Rubydora::Transactions.use_transactions = true
      yield(self)
      Rubydora::Transactions.use_transactions = old_state
    end

    def without_transactions(&block)
      old_state = Rubydora::Transactions.use_transactions
      Rubydora::Transactions.use_transactions = false
      yield(self)
      Rubydora::Transactions.use_transactions = old_state
    end

    # Roll-back transactions by reversing their outcomes
    # (or, in some cases, re-ingesting the object at the
    # previous state.
    def rollback
      without_transactions do
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
            # no-op
          end

          run_hook :after_rollback, :pid => options[:pid], :method => method, :options => options
        end
      end
      true
    end
  end

end
