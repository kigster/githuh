# frozen_string_literal: true

require 'spec_helper'

require 'githuh'
require 'aruba/rspec'

RSpec.describe Githuh::CLI::Commands::Version, type: :aruba do
  include_context 'aruba setup'

  context 'githuh version' do
    let(:args) { %w(version) }
    subject { output }
    it { should_not match /Githuh/ }
    it { should match /#{Githuh::VERSION}/ }
  end
end
