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

  spec.add_dependency "i18n",      "~> 0.7", ">= 0.7.0"
  spec.add_dependency "gpgme",     "~> 2.0", ">= 2.0.12"
  spec.add_dependency "highline",  "~> 1.7", ">= 1.7.8"
  spec.add_dependency "locale",    "~> 2.1", ">= 2.1.2"
  spec.add_dependency "colorize",  "~> 0.8", ">= 0.8.1"
  spec.add_dependency "net-ssh",   "~> 3.2", ">= 3.2.0"
  spec.add_dependency "net-sftp",  "~> 2.1", ">= 2.1.2"
  spec.add_dependency "clipboard", "~> 1.1", ">= 1.1.1"
  spec.add_dependency "rotp",      "~> 3.1", ">= 3.1.0"
end
