module Rubydora

# Provides class level methods for handling
# callback methods that alter object instances
  module Callbacks
    # add callback framework to base class
    # @param [Class] base 
    def self.included(base)
      base.extend ExtendableClassMethods
    end

    # hooks support
    module ExtendableClassMethods
      # creates the @hooks container ("hooks" are blocks or procs).
      # returns an array
      def hooks
        @hooks ||= {}
      end

      # register callback procs
      # @param [Array<Symbol>] hook name
      def register_callback *attrs
        attrs.each do |method_name|  
          next if methods.include? method_name.to_s
          instance_eval %Q{
            def #{method_name}(&blk)
              self.hooks[:#{method_name}] ||= []
              self.hooks[:#{method_name}] << blk
            end

            def clear_#{method_name}_blocks!
              self.hooks[:#{method_name}] = []
            end
          }

          class_eval %Q{
            def call_#{method_name}
              self.class.hooks[:#{method_name}] ||= []
              self.class.hooks[:#{method_name}].each do |h|
                instance_eval &h
              end
            end

          }
        end
      end
    end
  end
end
