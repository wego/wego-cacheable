require 'request_store'

module Cacheable
  module CacheVersion
    module_function

    NAMESPACE = 'Cache'
    EXPIRY = 0 # in dalli/memcached 0 means never expire

    def get
      RequestStore.store[:cache_version] ||= Rails.cache.read(@cache_key,
                                                              raw: true)
    end

    def inc
      RequestStore.store[:cache_version] = Rails.cache.increment(@cache_key, 1,
                                                                 expires_in: @expiry)
    end

    def init(version = nil)
      version ||= 1
      @cache_key ||= build_cache_key(NAMESPACE)
      @expiry ||= EXPIRY
      cached_version = Rails.cache.read(@cache_key, raw: true)

      if version.to_i > cached_version.to_i
        Rails.cache.write(@cache_key, version, raw: true, expires_in: @expiry)
        RequestStore.store[:cache_version] = version
      end
    end

    def namespace=(namespace)
      @cache_key = build_cache_key(namespace)
    end

    def expiry=(expiry)
      @expiry = expiry
    end

    def cache_key
      @cache_key
    end

    private

    def self.build_cache_key(namespace)
      "#{namespace || NAMESPACE}:Cache:version"
    end
  end
end
