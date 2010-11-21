# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'net/ssh/socks'

Gem::Specification.new do |s|
  s.name        = "net-ssh-socks"
  s.version     = Net::SSH::Socks::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mike Enriquez"]
  s.email       = ["mike@edgecase.com"]
  s.homepage    = ""
  s.summary     = %q{An extension to Net::SSH that adds dynamic port forwarding through a SOCKS proxy}
  s.description = %q{Net::SSH::Socks is a library for programmatically creating a SOCKS proxy. Similar to Net::SSH::Service::Forward#local except the host is dynamic (determined by the client application, such as a browser).}

  s.rubyforge_project = "net-ssh-socks"

  s.add_dependency "net-ssh", "~> 2.0.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
