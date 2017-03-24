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
caches_method :name_of_the_method
caches_method :name_of_the_method, expires_in: 1.day #defalut expires_in is 1 day
caches_method :name_of_the_method, include_locale: true #default include_locale is false
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cacheable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
