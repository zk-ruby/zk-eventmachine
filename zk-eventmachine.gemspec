# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "z_k/z_k_event_machine/version"

Gem::Specification.new do |s|
  s.name        = "zk-eventmachine"
  s.version     = ZK::ZKEventMachine::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan D. Simms"]
  s.email       = ["slyphon@hp.com"]
  s.homepage    = "https://github.com/slyphon/zk-eventmachine"
  s.summary     = %q{ZK client for EventMachine-based (async) applications}
  s.description = s.description

  s.add_dependency 'zk', '~> 0.9.0'

  # zk depends on slyphon-zookeeper, but we need at least this version
  s.add_dependency 'slyphon-zookeeper', '~> 0.8.1'
  s.add_dependency 'eventmachine',      '~> 1.0.0.beta.4'
  s.add_dependency 'deferred',          '~> 0.5.3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
