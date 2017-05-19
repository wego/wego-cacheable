# Cacheable

Gem for caching in Wego Rails apps

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cacheable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cacheable

## Usage

To include the caching feature for of the gem in your Rails apps models, create config/initializer/cacheable.rb with the following line:
```ruby
ActiveRecord::Base.send(:include, Cacheable::ActiveRecordExtensions)

Cacheable::CacheVersion.namespace = 'application_name'
Cacheable::CacheVersion.init
```
In your model, add the functions that you want to cache the data
```ruby
caches_method :method_name
caches_method :method_name, expires_in: 1.day #defalut expires_in is 1 day
caches_method :method_name, include_locale: true #default include_locale is false
```

In order to prevent too many request sent to caching storate (memcache) we will store cache in-memory by default. In-memory storage is only available per request. If you want to disable in-memory can set like this
```ruby
caches_method :method_name, memoized: false
```

### Notice
Need to use two separate define functions for instance and class methods (singeton methods)

```
class Test
    caches_method :a_defined_method
    caches_class_method :a_defined_class_method
    
    def a_defined_method
      #
    end
    
    def self.a_defined_class_method
      #
    end
end

```
## Generate methods
`caches_method :method_name` or `caches_class_method :method_name` will only generate cached method with same name `method_name` for caching and `delete_method_name_cache` for clearing cache.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cacheable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
