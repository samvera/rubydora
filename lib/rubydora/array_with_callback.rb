module Rubydora
  class ArrayWithCallback < Array

    [:<<, :collect!, :map!, :compact!, :concat, :delete, :delete_at, :delete_if, :pop, :push, :reject!, :replace, :select!, :[]=, :slice!, :uniq! ].each do |method|
      class_eval <<-RUBY
        def #{method.to_s} *args, &blk
          old = self.dup
          super(*args, &blk)
          callbacks({:+ => self - old, :- => old - self})
        end
      RUBY
    end

    def hooks
      @hooks ||= []
    end

    def callbacks changes = {}
      self.hooks.each do |h|
        h.call(self, changes)
      end
    end
  end
end
