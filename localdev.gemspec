# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'localdev.rb'

Gem::Specification.new do |s|
  s.name        = "localdev"
  s.version     = Localdev::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mark Jaquith"]
  s.email       = ["mark@jaquith.me"]
  s.homepage    = "http://github.com/markjaquith/Localdev"
  s.summary     = %q{Add locally hosted domains to your hosts file, and disable/enable their use}
  s.description = %q{Localdev manages part of your hosts file and lets you specify domains to host locally. You can quickly enable or disable local hosting of those domains.}
  s.has_rdoc = false

  # s.required_rubygems_version = ">= 1.3.6"
  # s.rubyforge_project         = "localdev"

  s.files              = `git ls-files`.split("\n")
  # s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables        = %w(localdev)
  s.require_paths      = ["lib"]
end
