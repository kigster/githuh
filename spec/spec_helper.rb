# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'githuh'
require 'aruba'
require 'aruba/rspec'
require 'rspec/its'
require 'timeout'

RSpec.configure do |spec|
  spec.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  spec.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  spec.include Aruba::Api

  spec.before(:each) do
    ::Githuh.in_test = true
  end

  spec.after(:each) do
    ::Githuh.launcher = nil
  end
end

Aruba.configure do |config|
  config.command_launcher = :in_process
  config.main_class       = ::Githuh::CLI::Launcher
end

::Dir.glob(::File.expand_path('../support/**/*.rb', __FILE__)).each { |f| require(f) }
