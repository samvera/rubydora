module Rubydora::Ext
  # Rubydora extension to load dynamically load modules into an object based on defined models
  module ModelLoader
    # @param [Hash] args
    # @option args [Class] :base_namespace
    # @option args [Class] :method
    # @option args [Class] :class
    #
    def self.load args = {}
      args[:class] ||=  Rubydora::DigitalObject
      args[:method] ||= :models

      args[:class].extension_parameters[:ModelLoaderMixin] ||= {}
      args[:class].extension_parameters[:ModelLoaderMixin][:namespaces] ||= []
      args[:class].extension_parameters[:ModelLoaderMixin][:namespaces] << args[:base_namespace]
      args[:class].extension_parameters[:ModelLoaderMixin][:method] ||= args[:method]
      args[:class].use_extension(ModelLoaderMixin)
    end

    module ModelLoaderMixin
      # @param [Class] base
      def self.extended(document)
        self.module_names(document).each do |model|
          document.class.extension_parameters[:ModelLoaderMixin][:namespaces].each do |ns|
            begin
              mod = self.string_to_constant [ns, model].compact.map { |x| x.to_s }.join("/")
              document.send(:extend, mod)
            rescue NameError, LoadError
            end
          end
        end
      end

      # convert a model string to a Ruby class (see ActiveSupport::Inflector#constantize)
      # @param [String] lower_case_and_underscored_word
      # @return [Module]
      def self.string_to_constant lower_case_and_underscored_word
        camel_cased_word = lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }

        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
          if Module.method(:const_get).arity == 1
          constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
          else
          constant = constant.const_defined?(name,false) ? constant.const_get(name) : constant.const_missing(name)
          end
        end
        constant
      end

      private
      def self.module_names(document)
        arr = document.send(document.class.extension_parameters[:ModelLoaderMixin][:method])
        arr &&= [arr] unless arr.is_a? Array
        arr.map { |x| x.gsub('info:fedora/', '').downcase.gsub(/[^a-z0-9_:]+/, '_').gsub(':', '/').gsub(/_{2,}/, '_').gsub(/^_|_$/, '')  }
      end
    end
  end
end
