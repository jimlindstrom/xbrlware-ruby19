# -*- encoding: utf-8 -*-
require File.expand_path('../lib/xbrlware-ruby19/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jim Lindstrom"]
  gem.email         = ["jim.lindstrom@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.add_dependency 'xmlsimple'
  gem.add_dependency 'date'
  gem.add_dependency 'bigdecimal'
  gem.add_dependency 'erb'
  gem.add_dependency 'set'
  gem.add_dependency 'stringio'
  gem.add_dependency 'cgi'
  gem.add_dependency 'logger'
  gem.add_dependency 'benchmark'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "xbrlware-ruby19"
  gem.require_paths = ["lib"]
  gem.version       = Xbrlware::Ruby19::VERSION
end
