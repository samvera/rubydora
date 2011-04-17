module Rubydora
  module RelationshipsMixin

    # FIXME: This should probably be defined on the DigitalObject
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

    def relationship predicate, args = {}
      arr = ArrayWithCallback.new(args[:values] || repository.find_by_sparql_relationship(fqpid, predicate))
      arr.on_change << lambda { |arr, diff| relationship_changed(predicate, diff, arr) } 

      arr
    end

    def relationship_changed predicate, diff, arr = []
      diff[:+] ||= []
      diff[:-] ||= []

      diff[:+].each do |o| 
        obj_uri = (( o.fqpid if o.respond_to? :fqpid ) || ( o.uri if o.respond_to? :uri ) || (o.to_s if o.respond_to? :to_s?) || o )
        repository.add_relationship :subject => fqpid, :predicate => predicate, :object => obj_uri
      end        

      diff[:-].each do |o| 
        obj_uri = (( o.fqpid if o.respond_to? :fqpid ) || ( o.uri if o.respond_to? :uri ) || (o.to_s if o.respond_to? :to_s?) || o )
        repository.purge_relationship :subject => fqpid, :predicate => predicate, :object => obj_uri
      end        
    end

    def relationships
      @relationships ||= {}
    end
  end
end
