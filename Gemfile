source "http://rubygems.org"
source 'http://localhost:50000'


# Specify your gem's dependencies in zk-em.gemspec
gemspec

git 'git://github.com/slyphon/zookeeper.git', :branch => 'dev/em' do
  gem 'slyphon-zookeeper', '~> 0.2.0'
end

platform :jruby do
  gem 'slyphon-log4j', '= 1.2.15'
  gem 'slyphon-zookeeper_jar', '= 3.3.3'
end

git 'git://github.com/slyphon/zk.git', :branch => 'dev/eventmachine' do
  gem 'zk', '~> 0.8.1'
end


# vim:ft=ruby
