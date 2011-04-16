module Rubydora
  module RelationshipsMixin

    RELS_EXT = { :parts => :hasPart }

    def self.included(base)
        RELS_EXT.each do |name, property|
          base.class_eval <<-RUBY
            def #{name.to_s}
              relationships[:#{name.to_s}] ||= ArrayWithCallback.new(repository.find_by_sparql_relationship(fqpid, '#{property.to_s}'))
              relationships[:#{name.to_s}] ||= ArrayWithCallback.new
              relationships[:#{name.to_s}].hooks << lambda { |arr, diff| relationship_#{name.to_s}_changed(arr, diff) } if @relationships[:#{name.to_s}].hooks.empty?
               relationships[:#{name.to_s}] 
            end

            def relationship_#{name.to_s}_changed arr, diff
              diff[:+] ||= []
              diff[:-] ||= []

              diff[:+].each do |o| 
                repository.add_relationship :subject => fqpid, :predicate => '#{property.to_s}', :object => o.fqpid
              end        

              diff[:-].each do |o| 
                repository.purge_relationship :subject => fqpid, :predicate => '#{property.to_s}', :object => o.fqpid
              end        
            end
          RUBY
        end
    end

    def relationships
      @relationships ||= {}
    end
  end
end
