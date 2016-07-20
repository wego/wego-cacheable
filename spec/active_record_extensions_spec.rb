require 'rails_helper'

module Cacheable
  RSpec.describe ActiveRecordExtensions do
    before do
      class FakeBase
        include Cacheable::ActiveRecordExtensions
      end
    end

    it 'exposes the cacheable methods' do
      expect do
        class Inherit < FakeBase
          caches_method :something
        end
      end.to_not raise_error
    end

    it 'maintains separate state between classes' do
      class InheritFirst < FakeBase
        caches_method :something
      end
      class InheritSecond < FakeBase
        caches_method :hello, :world
      end
      expect(InheritFirst.instance_eval { @cached_methods }).to eq([:something])
      expect(InheritSecond.instance_eval { @cached_methods }).to eq([:hello, :world])
    end
  end
end