module Rubydora
  ##
  # Provide access to registered content models
  # FIXME: Ruby 1.9 provides instance_exec, which should make it
  # possible to subsume this into Rubydora::RelationshipsMixin
  module ModelsMixin
 
    # Provides an accessor to the object content models
    # @param [Hash] args
    # @option args [Array] :values if nil, will query the resource index for related objects
    # @return [ArrayWithCallback<Rubydora::DigitalObject>] an array that will call the #relationship_changed callback when values are modified 
    def models args = {}
      @models = nil if args.delete(:refetch)
      @models ||= relationship('info:fedora/fedora-system:def/model#hasModel', :values => args[:values] || profile['objModels'] || [])
    end

    # provides a setter that behaves as does #models
    def models= arr
      arr &&= [arr] unless arr.is_a? Array
      old = models.dup || []
      arr = @models = relationship('info:fedora/fedora-system:def/model#hasModel', :values => arr.flatten)
      relationship_changed('info:fedora/fedora-system:def/model#hasModel', {:+ => arr - old, :- => old - arr }, @models)

      @models
    end
    alias_method :model=, :models=
  end
end
