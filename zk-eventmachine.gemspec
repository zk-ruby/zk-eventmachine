# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "z_k/z_k_event_machine/version"

Gem::Specification.new do |s|
  s.name        = "zk-eventmachine"
  s.version     = ZK::ZKEventMachine::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan D. Simms"]
  s.email       = ["slyphon@hp.com"]
  s.homepage    = ""
  s.summary     = %q{ZK client for EventMachine-based (async) applications}
  s.description = s.description

#   s.add_dependency('zk', '~> 0.6.5')
  s.add_dependency('eventmachine', '= 0.12.10')

  s.add_development_dependency('rspec', '~> 2.5.0')
  s.add_development_dependency('yard', '~> 0.7.0')
  s.add_development_dependency('autotest', '>= 4.4.0')
  s.add_development_dependency('flexmock', '~> 0.8.10')
  s.add_development_dependency('evented-spec', '~> 0.4.1')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
