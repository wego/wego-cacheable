require 'rails_helper'

RSpec.describe Cacheable do
  let(:cache_duration) { Cacheable.default_cache_duration }

  describe '.cache_key' do
    it 'returns the expected cache key' do
      key = Cacheable.cache_key(Object, 'send', 1, 2, 3, {})
      expect(key).to eq("#{Cacheable::CacheVersion.get}:#{Object.name}:send:1:2:3")
    end

    it 'returns the expected cache key with hash' do
      key = Cacheable.cache_key(Object, 'send', 1, 2, 3, { a: 1 }, {})
      expect(key).to eq("#{Cacheable::CacheVersion.get}:#{Object.name}:send:1:2:3:{:a=>1}")
    end

    it 'returns the expected cache key with locale' do
      key = Cacheable.cache_key(Object, 'send', 1, 2, 3, include_locale: true)
      expect(key).to eq("#{Cacheable::CacheVersion.get}:#{Object.name}:send:1:2:3:en")
    end
  end

  describe '.expire' do
    it 'expires the expected key' do
      expect(Rails.cache).to receive(:delete).with(
        "#{Cacheable::CacheVersion.get}:#{Object.name}:send:1:2:3"
      )
      Cacheable.expire(Object, 'send', 1, 2, 3, {})
    end

    it 'expires the expected key with locale' do
      expect(Rails.cache).to receive(:delete).with(
        "#{Cacheable::CacheVersion.get}:#{Object.name}:send:1:2:3:en"
      )
      Cacheable.expire(Object, 'send', 1, 2, 3, include_locale: true)
    end
  end

  describe 'caches_method' do
    before do
      Cacheable::CacheVersion.inc

      module CacheableInclude
        def a_defined_module_method(x)
          x
        end
      end

      module CacheableExtend
        def a_defined_module_class_method(x)
          x
        end
      end

      class CacheableBase
        def self.a_defined_super_class_method(x)
          x
        end
      end

      class CacheableClass1 < CacheableBase
        include Cacheable
        extend CacheableExtend
        include CacheableInclude

        attr_accessor :updated_at

        caches_method :method_1, :output, :method_2, :more_arguments, :contains?
        caches_method :with_expiry, expires_in: 5.minutes
        caches_method :a_defined_module_method
        caches_class_method :a_defined_module_class_method, :a_defined_super_class_method

        def method_1
          1
        end

        def method_2(something, another)
          [something, another]
        end

        def more_arguments(a, b = 1)
          [a, b]
        end

        def output(outputter)
          outputter.output
        end

        def with_expiry
          123
        end

        def contains?
          123
        end
      end

      class CacheableClass2
        include Cacheable

        caches_method :method_1, :method_2, :a_class_method, :method_3
        caches_method :method_5, memoized: true
        caches_class_method :method_4, memoized: true
        caches_class_method :with_expiry, expires_in: 6.minutes
        caches_class_method :method_with_locale, include_locale: true
        caches_class_method :a_class_method, :method_3

        def method_1
          1
        end

        def method_2
          2
        end

        def self.method_with_locale(a, b = 1)
          [a, b]
        end

        def self.method_3(something, another)
          [something, another]
        end

        def self.method_4(x)
          x
        end

        def method_5(x)
          x
        end

        def self.a_class_method(a, b, c = 1, d = 2, e: 3)
          "#{a}-#{b}-#{c}-#{d}-#{e}"
        end

        def a_class_method
          "This is an instance method but the name is same as one of class's methods"
        end

        def self.with_expiry
          345
        end
      end
    end

    describe 'caching' do
      context 'without caching' do
        let(:instance_1) { CacheableClass1.new }
        it 'calls the actual method on first call' do
          outputter = double(output: 1)
          instance_1.output(outputter)
          expect(outputter).to have_received(:output)
        end
      end

      context 'with caching' do
        let(:instance_1) { CacheableClass1.new }
        it 'gets the value from the cache for subsequent calls' do
          outputter = double(output: 1)
          instance_1.output(outputter)
          instance_1.output(outputter)
          instance_1.output(outputter)
          expect(outputter).to have_received(:output).once
        end
      end
    end

    describe 'with memoized option' do
      subject { Rails.cache }

      context 'given class methods' do
        it { expect(subject).to receive(:fetch).once.and_return(4) }
        after do
          CacheableClass2.method_4(4)
          CacheableClass2.method_4(4)
        end
      end

      context 'given instance methods' do
        let(:instance_2) { CacheableClass2.new }
        it { expect(subject).to receive(:fetch).once.and_return(5) }
        after do
          instance_2.method_5(5)
          instance_2.method_5(5)
        end
      end

      context 'given methods without memoized' do
        let(:instance_1) { CacheableClass1.new }
        it { expect(subject).to receive(:fetch).twice.and_return(1) }
        after do
          instance_1.method_1
          instance_1.method_1
        end
      end
    end

    describe 'instance methods' do
      let(:instance_1) { CacheableClass1.new }

      it 'returns correct value when called directly' do
        expect(instance_1.method_1).to eq(1)
      end

      it 'handles method names with punctuation marks' do
        expect(instance_1.contains?).to eq(123)
      end

      it 'calls Rails.cache with the proper cache key' do
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{instance_1.class.name}:#{instance_1.object_id}:more_arguments:0:1",
          expires_in: cache_duration
        )
        instance_1.more_arguments(0, 1)
      end

      it 'calls Rails.cache with the proper cache key with updated_at' do
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{instance_1.class.name}:#{instance_1.object_id}:#{Date.today}:more_arguments:0:1",
          expires_in: cache_duration
        )
        instance_1.updated_at = Date.today
        instance_1.more_arguments(0, 1)
      end

      it 'calls Rails.cache with the proper cache duration' do
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{instance_1.class.name}:#{instance_1.object_id}:with_expiry:",
          expires_in: 5.minutes
        )
        instance_1.with_expiry
      end

      it 'uses id in the cache key and sets a duration' do
        def instance_1.id
          123
        end
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{instance_1.class.name}:#{instance_1.id}:more_arguments:0:1",
          expires_in: cache_duration
        )
        instance_1.more_arguments(0, 1)
      end

      context 'with method is defined from included module' do
        it 'returns correct value' do
          expect(instance_1.a_defined_module_method(2)).to eq(2)
        end

        it 'calls Rails.cache with the expected arguments' do
          expect(Rails.cache).to receive(:fetch).with(
            "#{Cacheable::CacheVersion.get}:#{instance_1.class.name}:#{instance_1.object_id}:a_defined_module_method:2", expires_in: cache_duration
          )
          instance_1.a_defined_module_method(2)
        end
      end

      describe 'arguments' do
        let(:instance_1) { CacheableClass1.new }

        it 'returns the argument' do
          expect(instance_1.method_2(3, 5)).to eq([3, 5])
        end

        it 'different arguments will return different results' do
          expect(instance_1.method_2(3, 4)).to eq([3, 4])
          expect(instance_1.method_2(4, 5)).to eq([4, 5])
        end
      end
    end

    describe 'multiple declarations' do
      let(:instance_2) { CacheableClass2.new }
      specify 'method_1 must return 1' do
        expect(instance_2.method_1).to eq(1)
      end

      specify 'method_2 must return 2' do
        expect(instance_2.method_2).to eq(2)
      end
    end

    describe 'class methods' do
      let(:instance_2) { CacheableClass2.new }

      it 'returns correct value when called directly' do
        expect(CacheableClass2.a_class_method(1, 2)).to eq('1-2-1-2-3')
      end

      it 'will cache the class method if there is an instance method with same name' do
        expect(instance_2.a_class_method).to eq(
          "This is an instance method but the name is same as one of class's methods"
        )
      end

      it 'calls Rails.cache with the expected arguments' do
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{CacheableClass2.name}:a_class_method:x:y", expires_in: cache_duration
        )
        CacheableClass2.a_class_method('x', 'y')
      end

      it 'calls Rails.cache with the expected arguments with locale' do
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{CacheableClass2.name}:method_with_locale:3:1:en", expires_in: cache_duration
        )
        CacheableClass2.method_with_locale(3, 1)
      end

      it 'calls Rails.cache with the provided duration' do
        expect(Rails.cache).to receive(:fetch).with(
          "#{Cacheable::CacheVersion.get}:#{CacheableClass2.name}:with_expiry:",
          expires_in: 6.minutes
        )
        CacheableClass2.with_expiry
      end

      context 'with method is defined from extend module' do
        it 'returns correct value' do
          expect(CacheableClass1.a_defined_module_class_method(2)).to eq(2)
        end

        it 'calls Rails.cache with the expected arguments' do
          expect(Rails.cache).to receive(:fetch).with(
            "#{Cacheable::CacheVersion.get}:#{CacheableClass1.name}:a_defined_module_class_method:2", expires_in: cache_duration
          )
          CacheableClass1.a_defined_module_class_method(2)
        end
      end

      context 'with method is defined from supper class' do
        it 'returns correct value' do
          expect(CacheableClass1.a_defined_super_class_method(3)).to eq(3)
        end

        it 'calls Rails.cache with the expected arguments' do
          expect(Rails.cache).to receive(:fetch).with(
            "#{Cacheable::CacheVersion.get}:#{CacheableClass1.name}:a_defined_super_class_method:3", expires_in: cache_duration
          )
          CacheableClass1.a_defined_super_class_method(3)
        end
      end

      describe 'arguments' do
        it 'returns the argument' do
          expect(CacheableClass2.method_3(3, 5)).to eq([3, 5])
        end

        it 'different arguments will return different results' do
          expect(CacheableClass2.method_3(3, 4)).to eq([3, 4])
          expect(CacheableClass2.method_3(8, 9)).to eq([8, 9])
        end
      end

      describe 'delete_cache' do
        it 'calls Rails.cache.delete' do
          CacheableClass2.method_3(4, 5)
          expect(Rails.cache).to receive(:delete).with(
            "#{Cacheable::CacheVersion.get}:#{CacheableClass2.name}:method_3:4:5"
          )
          CacheableClass2.delete_method_3_cache(4, 5)
        end
      end
    end
  end
end
