module Rubydora::Ext
  # Rubydora extension to load dynamically load modules into an object based on defined models
  module ModelLoader
    # @param [Hash] args
    # @option args [Class] :base_namespace
    # @option args [Class] :class
    def self.load args = {}
      args[:class] ||=  Rubydora::DigitalObject

      args[:class].extension_parameters[:ModelLoaderMixin] ||= {}
      args[:class].extension_parameters[:ModelLoaderMixin][:namespaces] ||= []
      args[:class].extension_parameters[:ModelLoaderMixin][:namespaces] << args[:base_namespace]
      args[:class].use_extension(ModelLoaderMixin)
    end

    # Load Datastreams mixin
    module ModelLoaderMixin
      # @param [Class] base
      def self.extended(document)
        document.models.each do |model|
          document.class.extension_parameters[:ModelLoaderMixin][:namespaces].each do |ns|
            begin
              mod = self.string_to_constant [ns, model.gsub('info:fedora/', '').gsub(':', '/').downcase].compact.map { |x| x.to_s }.join("::")
              document.send(:extend, mod)
            rescue NameError
            end
          end
        end
      end

      def self.string_to_constant lower_case_and_underscored_word
        camel_cased_word = lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }

        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
          constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
        constant
      end
    end
  end
end
