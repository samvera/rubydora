module Rubydora
  ##
  # Provide access to registered content models
  # FIXME: Given additional relationships configuration
  #        this could be subsumed by Rubydora::RelationshipsMixin
  module ModelsMixin
    def models args = {}
      @models = nil if args.delete(:refetch)
      @models ||= relationship('info:fedora/fedora-system:def/model#hasModel', :values => profile['objModels'] || [])
    end

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
