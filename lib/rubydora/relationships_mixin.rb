module Rubydora
  #
  # This model inject RELS-EXT-based helper methods 
  # for Fedora objects
  #
  module RelationshipsMixin

    # FIXME: This should probably be defined on the DigitalObject
    # Map Rubydora accessors to Fedora RELS-EXT predicates
    RELS_EXT = {"annotations"=>"info:fedora/fedora-system:def/relations-external#hasAnnotation",
                "has_metadata"=>"info:fedora/fedora-system:def/relations-external#hasMetadata",
                "description_of"=>"info:fedora/fedora-system:def/relations-external#isDescription_of",
                "part_of"=>"info:fedora/fedora-system:def/relations-external#isPart_of",
                "descriptions"=>"info:fedora/fedora-system:def/relations-external#hasDescription",
                "dependent_of"=>"info:fedora/fedora-system:def/relations-external#isDependent_of",
                "constituents"=>"info:fedora/fedora-system:def/relations-external#hasConstituent",
                "parts"=>"info:fedora/fedora-system:def/relations-external#hasPart",
                "memberOfCollection"=>"info:fedora/fedora-system:def/relations-external#isMemberOfCollection",
                "member_of"=>"info:fedora/fedora-system:def/relations-external#isMember_of",
                "equivalents"=>"info:fedora/fedora-system:def/relations-external#hasEquivalent",
                "derivations"=>"info:fedora/fedora-system:def/relations-external#hasDerivation",
                "derivation_of"=>"info:fedora/fedora-system:def/relations-external#isDerivation_of",
                "subsets"=>"info:fedora/fedora-system:def/relations-external#hasSubset",
                "annotation_of"=>"info:fedora/fedora-system:def/relations-external#isAnnotation_of",
                "metadata_for"=>"info:fedora/fedora-system:def/relations-external#isMetadataFor",
                "dependents"=>"info:fedora/fedora-system:def/relations-external#hasDependent",
                "subset_of"=>"info:fedora/fedora-system:def/relations-external#isSubset_of",
                "constituent_of"=>"info:fedora/fedora-system:def/relations-external#isConstituent_of",
                "collection_members"=>"info:fedora/fedora-system:def/relations-external#hasCollectionMember",
                "members"=>"info:fedora/fedora-system:def/relations-external#hasMember"}

    # generate accessor methods for each RELS_EXT property
    def self.included(base)

        # FIXME: ugly, but functional..
        RELS_EXT.each do |name, property|
          base.class_eval <<-RUBY
            def #{name.to_s} args = {}
              relationships[:#{name}] = nil if args.delete(:refetch)
              relationships[:#{name}] ||= relationship('#{property}', args)
            end

            def #{name.to_s}= arr
              arr &&= [arr] unless arr.is_a? Array
              old = #{name.to_s}.dup || []
              arr = relationships[:#{name}] = relationship('#{property}', :values => arr.flatten)
              relationship_changed('#{property}', {:+ => arr - old, :- => old - arr },  arr)

              arr
            end
          RUBY
        end
    end
          
    ##
    # Provides an accessor to the `predicate` RELS-EXT relationship
    # Using ArrayWithCallback, will commit any changes to Fedora
    #
    # @param [String] predicate
    # @param [Hash] args
    # @option args [Array] :values if nil, will query the resource index for related objects
    # @return [ArrayWithCallback<Rubydora::DigitalObject>] an array that will call the #relationship_changed callback when values are modified
    def relationship predicate, args = {}
      arr = ArrayWithCallback.new(args[:values] || repository.find_by_sparql_relationship(fqpid, predicate))
      arr.on_change << lambda { |arr, diff| relationship_changed(predicate, diff, arr) } 

      arr
    end


    ##
    # Given a predicate and a diff between before and after states
    # commit the appropriate changes to Fedora
    #
    # @param [String] predicate
    # @param [Hash] diff
    # @option diff [Hash] :+ additions
    # @option diff [Hash] :- deletions
    # @param [Array] arr the current relationship state
    def relationship_changed predicate, diff, arr = []
      diff[:+] ||= []
      diff[:-] ||= []

      diff[:+].each do |o| 
        add_relationship(predicate, o)
      end        

      diff[:-].each do |o| 
        purge_relationship(predicate, o)
      end        
    end

    # Add a relationship for this object
    # @param [String] predicate
    # @param [String, Rubydora::DigitalObject] object
    # @return self
    def add_relationship predicate, object
      obj_uri = (( object.fqpid if object.respond_to? :fqpid ) || ( object.uri if object.respond_to? :uri ) || (object.to_s if object.respond_to? :to_s?) || object )
      repository.add_relationship :subject => fqpid, :predicate => predicate, :object => obj_uri
      self
    end

    # Purge a relationship from this object
    # @param [String] predicate
    # @param [String, Rubydora::DigitalObject] object
    # @return self
    def purge_relationship predicate, object
      obj_uri = (( object.fqpid if object.respond_to? :fqpid ) || ( object.uri if object.respond_to? :uri ) || (object.to_s if object.respond_to? :to_s?) || object )
      repository.purge_relationship :subject => fqpid, :predicate => predicate, :object => obj_uri
    end

    # accessor to all retrieved relationships
    # @return [Hash]
    def relationships
      @relationships ||= {}
    end
  end
end
