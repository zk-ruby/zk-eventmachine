source :rubygems

# gem 'zk', :path => '~/zk'

group :test do
  gem 'rspec',       '~> 2.8.0'
  gem 'flexmock',    '~> 0.8.10'
  gem 'evented-spec','~> 0.9.0'
end

group :docs do
  gem 'yard', '~> 0.8.0'

  platform :mri_19 do
    gem 'redcarpet'
  end
end

group :development do
  gem 'guard',          :require => false
  gem 'guard-rspec',    :require => false
  gem 'guard-shell',    :require => false
  gem 'guard-bundler',  :require => false

  if RUBY_PLATFORM =~ /darwin/i
    gem 'growl',       :require => false
    gem 'rb-readline', :platform => :ruby
  end

  gem 'rake'
  gem 'pry'
end

# Specify your gem's dependencies in zk-em.gemspec
gemspec

# vim:ft=ruby
