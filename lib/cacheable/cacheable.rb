module Cacheable
  extend ActiveSupport::Concern

  def self.default_cache_duration
    @duration
  end

  def self.default_cache_duration=(duration)
    @duration = duration
  end

  def self.currency
    @currency
  end

  def self.currency=(currency)
    @currency = currency
  end

  self.default_cache_duration = 1.day

  def self.class_signature(obj)
    signature = if obj.is_a?(Class) || obj.is_a?(Module)
                  obj.name
                else
                  id = obj.respond_to?(:id) ? obj.id : obj.object_id
                  sign = "#{obj.class.name}:#{id}"
                  if obj.respond_to?(:updated_at) && obj.updated_at
                    sign += ":#{obj.updated_at}"
                  end
                  sign
                end
    "#{Cacheable::CacheVersion.get}:#{signature}"
  end

  def self.cache_key(klass, method, *args)
    options = args.pop
    key_parts = [class_signature(klass), method, args]
    key_parts << I18n.locale if options.is_a?(Hash) && options[:include_locale] == true
    key_parts << Cacheable.currency if options.is_a?(Hash) && options[:include_currency] == true && Cacheable.currency
    key_parts.join(':')
  end

  def self.expire(klass, method, *args)
    Rails.cache.delete cache_key(klass, method, *args)
  end

  included do
    class_eval do
      def self.caches_method(*names)
        opts = names.extract_options!
        @cache_options ||= {}
        names.each do |name|
          @cache_options[name] = opts
          add_method_with_cache name
        end
      end

      def self.caches_class_method(*names)
        opts = names.extract_options!
        @cache_options ||= {}
        names.each do |name|
          @cache_options[name] = opts
          add_class_method_with_cache name
        end
      end

      private

      def self.add_method_with_cache(name)
        prepend cache_module_for(name)
      end

      def self.add_class_method_with_cache(name)
        singleton_class.prepend cache_module_for(name)
      end

      def self.cache_module_for(target)
        options = @cache_options[target]
        duration = options.delete(:expires_in)
        duration ||= Cacheable.default_cache_duration
        name = target.to_s.sub(/([?!=])$/, '')
        punctuation = Regexp.last_match(1)
        cache_module_name = "#{name}_cache".camelize

        return const_get(cache_module_name) if const_defined? cache_module_name

        cache_module = Module.new do
          define_method(target) do |*args|
            key = Cacheable.cache_key(self, target, *args, options)
            generate_request_store(key, options) do
              Rails.cache.fetch(key, expires_in: duration) do
                super(*args)
              end
            end
          end

          define_method("delete_#{name}_cache#{punctuation}") do |*args|
            key = Cacheable.cache_key(self, target, *args, options)
            RequestStore.store[key.to_sym] = nil
            Rails.cache.delete(key)
          end

          private
          def generate_request_store(key, options)
            unless (options && options[:memoized] == false) || Rails.application.config.action_controller.perform_caching == false
              RequestStore.store[key.to_sym] ||= yield
            else
              yield
            end
          end
        end

        const_set(cache_module_name, cache_module)
      end
    end
  end
end
