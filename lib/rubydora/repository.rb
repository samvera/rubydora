module Rubydora
  class Repository
    include ResourceIndex
    include RestApiClient
    attr_reader :config

    def initialize options = {}
      @config = options
    end

    def find pid
      DigitalObject.find(pid, self)
    end


  end
end
