module Cacheable
  module ActiveRecordExtensions
    extend ActiveSupport::Concern
    included do
      module IncludeInheritedCacheable
        def inherited(kls)
          super(kls)
          kls.send(:include, Cacheable)
        end
      end

      singleton_class.prepend IncludeInheritedCacheable

      # Existing subclasses pick up the model extension as well
      self.descendants.each do |kls|
        kls.send(:include, Cacheable)
      end
    end
  end
end