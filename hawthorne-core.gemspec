Gem::Specification.new do |spec|

  spec.name          = 'hawthorne-core'
  spec.version       = '0.1.0'
  spec.summary       = 'Hawthorne Core Code'
  spec.authors       = ['Hawthorne']
  spec.files         = Dir['app/**/*', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'
  spec.add_dependency 'rails'

end