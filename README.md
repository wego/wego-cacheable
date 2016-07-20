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
```
In your model, add the functions that you want to cache the data
```ruby
caches_method :name_of_the_method
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cacheable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
