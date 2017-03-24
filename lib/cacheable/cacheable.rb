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
    include_locale = args.last.is_a?(Hash) && args.last.include?(:include_locale) ?
                        args.pop.delete(:include_locale) :
                        false
    key_parts = [class_signature(klass), method, args]
    key_parts << I18n.locale if include_locale
    key_parts.join(':')
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
          alias_method_chain name, :cache
        end
      end

      def self.singleton_method_added(name)
        super
        if cacheable? name
          generated_method = generate_method_with_cache(name)
          singleton_class.instance_eval do
            class_eval(generated_method, __FILE__, __LINE__ + 1)
            alias_method_chain name, :cache
          end
        end
      end

      private

      def self.generate_method_with_cache(target)
        options = @options[target]
        duration = options.delete(:expires_in)
        duration ||= Cacheable.default_cache_duration
        name = target.to_s.sub(/([?!=])$/, '')
        punctuation = Regexp.last_match(1)

        <<-EVAL
        def #{name}_with_cache#{punctuation}(*args)
          key = Cacheable.cache_key(self, '#{name}', *args#{", #{options}" unless options.empty?})
          #{generate_request_store(target)} Rails.cache.fetch(key, expires_in: #{duration}) do
            #{name}_without_cache#{punctuation}(*args)
          end
        end

        def delete_#{name}_cache#{punctuation}(*args)
          key = Cacheable.cache_key(self, '#{name}', *args#{", #{options}" unless options.empty?})
          RequestStore.store[key.to_sym] = nil
          Rails.cache.delete(key)
        end
        EVAL
      end

      def self.generate_request_store(target)
        'RequestStore.store[key.to_sym] ||=' if @options[target][:memoized] == true
      end
    end
  end
end
