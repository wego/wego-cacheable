module Cacheable
  extend ActiveSupport::Concern

  def self.default_cache_duration
    @duration
  end

  def self.default_cache_duration=(duration)
    @duration = duration
  end

  self.default_cache_duration = 1.day

  def self.class_signature(obj)
    signature = if obj.is_a?(Class) || obj.is_a?(Module)
                  obj.name
                else
                  id = obj.respond_to?(:id) ? obj.id : obj.object_id
                  "#{obj.class.name}:#{id}"
                end
    "#{Cacheable::CacheVersion.get}:#{signature}"
  end

  def self.cache_key(klass, method, *args)
    "#{class_signature(klass)}:#{method}:#{args.join(':')}"
  end

  def self.expire(klass, method, *args)
    Rails.cache.delete cache_key(klass, method, *args)
  end

  included do
    class_eval do
      def self.caches_method(*names)
        opts = names.extract_options!

        @cached_methods ||= []
        @cached_methods |= names

        @options ||= {}
        names.each { |name| @options[name] = opts }
      end

      def self.cacheable?(name)
        @cached_methods.present? && @cached_methods.delete(name).present?
      end

      def self.method_added(name)
        super
        if cacheable? name
          class_eval(generate_method_with_cache(name), __FILE__, __LINE__ + 1)

          target_name, punctuation = name.to_s.sub(/([?!=])$/, ''), $1
          alias_method :"#{target_name}_without_cache#{punctuation}", name
          alias_method name, :"#{target_name}_with_cache#{punctuation}"
        end
      end

      def self.singleton_method_added(name)
        super
        if cacheable? name
          generated_method = generate_method_with_cache(name)
          singleton_class.instance_eval do
            class_eval(generated_method, __FILE__, __LINE__ + 1)

            target_name, punctuation = name.to_s.sub(/([?!=])$/, ''), $1
            alias_method :"#{target_name}_without_cache#{punctuation}", name
            alias_method name, :"#{target_name}_with_cache#{punctuation}"
          end
        end
      end

      private

      def self.generate_method_with_cache(target)
        duration = @options[target][:expires_in]
        duration ||= Cacheable.default_cache_duration
        name, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
        <<-EVAL
        def #{name}_with_cache#{punctuation}(*args)
          key = Cacheable.cache_key(self, '#{name}', *args)
          #{generate_request_store(target)} Rails.cache.fetch(key, expires_in: #{duration}) do
            #{name}_without_cache#{punctuation}(*args)
          end
        end
        EVAL
      end

      def self.generate_request_store(target)
        'RequestStore.store[key.to_sym] ||=' if @options[target][:memoized] == true
      end
    end
  end
end
