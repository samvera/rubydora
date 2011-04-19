module Rubydora
# Copied in part from projectblacklight.org
  module ExtensionParameters
    # setup extension support
    def self.included(base)
      base.extend ExtendableClassMethods

      # Provide a class-level hash for extension parameters
      base.class_eval do
        def self.extension_parameters
          ## This variable should NOT be @@, since we're in a class method,
          # it's just @ to be a class variable. Confusing, but it
          # passes the tests this way.       
          @extension_parameters ||= {}
        end      
      end

      base.after_initialize do
        apply_extensions
      end
    end

    # try to apply registered extensions
    def apply_extensions
      self.class.registered_extensions.each do |registration|
        self.extend( registration[:module_obj] ) if registration[:condition_proc].nil? || registration[:condition_proc].call( self )
      end
    end

  # Certain class-level modules needed for the document-specific
  # extendability architecture
  module ExtendableClassMethods
    attr_writer :registered_extensions

    # registered_extensions accessor
    # @return [Array]
    def registered_extensions
      @registered_extensions ||= []
    end

    # register extensions
    # @param [Module] module_obj
    # @yield &condition
    def use_extension( module_obj, &condition )
      registered_extensions << {:module_obj => module_obj, :condition_proc => condition}    
    end

  end
  end
end
