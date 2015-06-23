# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'mpw'
  spec.version       = File.open('VERSION').read
  spec.authors       = ['nishiki']
  spec.email         = ['gems@yae.im']
  spec.summary       = 'Manage your password'
  spec.description   = 'Save and read your password with gpg'
  spec.homepage      = 'https://github.com/nishiki/manage-password'
  spec.license       = 'GPL'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ['mpw', 'mpw-server', 'mpw-ssh']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
end
