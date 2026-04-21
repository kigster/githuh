# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative 'lib/githuh/version'

Gem::Specification.new do |spec|
  spec.name    = 'githuh'
  spec.version = Githuh::VERSION
  spec.authors = ['Konstantin Gredeskoul']
  spec.email   = %w(kigster@gmail.com)

  spec.summary = "Extensible CLI helper client for Github, for automating various tasks, such as — generating a list of org's repos and converting it into a pretty markdown, etc"
  spec.license = 'MIT'

  spec.description = "Generate repository list, show user info and more."

  spec.homepage = 'https://github.com/kigster/githuh'

  spec.files                 = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir                = 'exe'
  spec.executables           = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '~> 4.0'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'colored2', '~> 3'
  spec.add_dependency 'dry-cli'
  spec.add_dependency 'hashie'
  spec.add_dependency 'octokit'
  spec.add_dependency 'tty-box'
  spec.add_dependency 'tty-progressbar'
  spec.add_dependency 'tty-screen'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
