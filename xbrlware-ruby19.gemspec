# -*- encoding: utf-8 -*-
require File.expand_path('../lib/xbrlware-ruby19/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jim Lindstrom"]
  gem.email         = ["jim.lindstrom@gmail.com"]
  gem.description   = %q{Re-packaging of xbrlware for ruby19}
  gem.summary       = %q{Re-packaging of xbrlware for ruby19}
  gem.homepage      = ""

  gem.add_dependency 'xml-simple'
  #gem.add_dependency 'date'
  gem.add_dependency 'bigdecimal'
  #gem.add_dependency 'erb'
  #gem.add_dependency 'set'
  #gem.add_dependency 'stringio'
  #gem.add_dependency 'cgi'
  gem.add_dependency 'logger'
  #gem.add_dependency 'benchmark'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "xbrlware-ruby19"
  gem.require_paths = ["lib"]
  gem.version       = Xbrlware::VERSION
end
