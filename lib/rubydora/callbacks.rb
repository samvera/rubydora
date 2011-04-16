module Rubydora
# Class level methods for altering object instances
  module Callbacks
    
    # method that only accepts a block
    # The block is executed when an object is created via #new -> SolrDoc.new
    # The blocks scope is the instance of the object.
    def after_initialize(&blk)
      hooks << blk
    end
    
    # Removes the current set of after_initialize blocks.
    # You would use this if you wanted to open a class back up,
    # but clear out the previously defined blocks.
    def clear_after_initialize_blocks!
      @hooks = []
    end
    
    # creates the @hooks container ("hooks" are blocks or procs).
    # returns an array
    def hooks
      @hooks ||= []
    end
    
  end
end
