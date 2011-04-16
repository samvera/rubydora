module Rubydora
  module ModelsMixin
    def models
      @models ||= ArrayWithCallback.new(profile['objModels'] || []) if profile
      @models ||= ArrayWithCallback.new

      @models.hooks << lambda { |arr, diff| models_changed(arr, diff) } if @models.hooks.empty?

      @models

    end

    def models= str
      arr = []
      arr << str
      arr.flatten!
      old = models.dup
      @models = ArrayWithCallback.new(arr)
      @models.hooks << lambda { |arr, diff| models_changed(arr, diff) } if @models.hooks.empty?
      models_changed(@models, {:+ => arr - old, :- => old - arr })

      @models
    end
    alias_method :model=, :models=

    def models_changed arr = nil, diff = {}
      # ??
      diff[:+] ||= []
      diff[:-] ||= []

      diff[:+].each do |o| 
repository.add_relationship :subject => fqpid, :predicate => 'info:fedora/fedora-system:def/model#hasModel', :object => o
      end

      diff[:-].each do |o| 
repository.purge_relationship :subject => fqpid, :predicate => 'info:fedora/fedora-system:def/model#hasModel', :object => o
      end  
    end
  end
end
