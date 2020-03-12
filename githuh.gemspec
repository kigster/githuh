# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'githuh/version'

Gem::Specification.new do |spec|
  spec.name          = 'githuh'
  spec.version       = '0.1.0'
  spec.authors       = ['Konstantin Gredeskoul']
  spec.email         = %w(kigster@gmail.com)

  spec.summary       = "Extensible CLI helper client for Github, for automating various tasks, such as — generating a list of org's repos and converting it into a pretty markdown, etc"

  spec.description   = "Extensible CLI helper client for Github, for automating various tasks, such as — generating a list of org's repos and converting it into a pretty markdown, etc"

  spec.homepage      = 'https://github.com/kigster/githuh'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency 'dry-cli'

  spec.add_development_dependency 'aruba'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'relaxed-rubocop'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
