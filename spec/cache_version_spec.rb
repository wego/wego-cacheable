require 'rails_helper'

module Cacheable
  RSpec.describe CacheVersion, type: :model do
    describe 'namespacing' do
      it 'allows modifying of cache key' do
        CacheVersion.namespace = 'Test'
        expect(CacheVersion.cache_key).to match(/Test/)
      end

      it 'uses default namespace when nil is set' do
        CacheVersion.namespace = nil
        expect(CacheVersion.cache_key).to match(/#{CacheVersion::NAMESPACE}/)
      end
    end

    describe 'versioning' do
      before do
        Rails.cache.delete CacheVersion.cache_key
        CacheVersion.expiry = 1.year
        CacheVersion.init
      end

      it 'returns 1 on first get' do
        expect(CacheVersion.get).to be 1
      end

      it 'increments value' do
        expect(CacheVersion.inc).to be 2
      end

      it 'returns the incremented value after incrementing' do
        CacheVersion.inc
        expect(CacheVersion.get).to be 2
      end

      it 'will not reset the value when calling init the second time' do
        CacheVersion.inc
        CacheVersion.init
        expect(CacheVersion.get).to be 2
      end
    end
  end
end