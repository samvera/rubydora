module Rubydora
  # Fedora Repository object that provides API access
  class Repository
    include ResourceIndex
    include RestApiClient

    # repository configuration (see #initialize)
    attr_reader :config

    # @param [Hash] options
    # @option options [String] :url
    # @option options [String] :user
    # @option options [String] :password
    def initialize options = {}
      @config = options
    end

    # {include:DigitalObject.find}
    def find pid
      DigitalObject.find(pid, self)
    end


  end
end
