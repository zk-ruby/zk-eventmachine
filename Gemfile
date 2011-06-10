source "http://rubygems.org"
source 'http://localhost:50000'


# Specify your gem's dependencies in zk-em.gemspec
gemspec

git 'git://github.com/slyphon/zookeeper.git', :branch => 'dev/em' do
  gem 'slyphon-zookeeper', '~> 0.1.7'
end

git 'git://github.com/slyphon/zk.git', :branch => 'dev/eventmachine' do
  gem 'zk', '~> 0.8.0'
end

# vim:ft=ruby
