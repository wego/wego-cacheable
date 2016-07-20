module Cacheable
  module ActiveRecordExtensions
    extend ActiveSupport::Concern
    included do
      class << self
        def inherited_with_cache_extensions(kls)
          inherited_without_cache_extensions kls
          kls.send(:include, Cacheable)
        end
        alias_method_chain :inherited, :cache_extensions
      end
      # Existing subclasses pick up the model extension as well
      self.descendants.each do |kls|
        kls.send(:include, Cacheable)
      end
    end
  end
end