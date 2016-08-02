# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'mpw'
  spec.version       = File.open('VERSION').read
  spec.authors       = ['Adrien Waksberg']
  spec.email         = ['mpw@yae.im']
  spec.summary       = 'MPW is a software to crypt and manage your passwords'
  spec.description   = 'Manage your passwords in all security with MPW, we use GPG to encrypt your passwords'
  spec.homepage      = 'https://github.com/nishiki/manage-password'
  spec.license       = 'GPL-2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ['mpw']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency "i18n"
  spec.add_dependency "gpgme"
  spec.add_dependency "highline"
  spec.add_dependency "locale"
  spec.add_dependency "colorize"
  spec.add_dependency "net-ssh"
  spec.add_dependency "net-scp"
  spec.add_dependency "clipboard"
  spec.add_dependency "rotp"
end
