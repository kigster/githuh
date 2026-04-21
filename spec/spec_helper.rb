# frozen_string_literal: true

ENV['RUBYOPT'] = '-W0'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'aruba'
require 'aruba/rspec'
require 'rspec/its'
require 'timeout'

if ARGV.empty?
  require "simplecov"
  require "coverage/badge"

  SimpleCov.start do
    add_filter "/spec/"
    self.formatters = SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::HTMLFormatter,
        Coverage::Badge::Formatter
      ]
    )
  end

  SimpleCov.at_exit do
    SimpleCov.result.format!
    # rubocop: disable RSpec/Output
    puts "Coverage: #{SimpleCov.result.covered_percent.round(2)}%"
    # rubocop: enable RSpec/Output
    FileUtils.mv("coverage/badge.svg", "docs/img/badge.svg")
  end
end

require 'githuh'

RSpec.configure do |spec|
  spec.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  spec.raise_errors_for_deprecations!

  spec.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  spec.include Aruba::Api

  spec.before do
    Githuh.in_test = true
  end

  spec.after do
    Githuh.launcher = nil
  end
end

Aruba.configure do |config|
  config.command_launcher = :in_process
  config.main_class       = Githuh::CLI::Launcher
end

Dir.glob(File.expand_path('support/**/*.rb', __dir__)).each { |f| require(f) }

load_aruba!
