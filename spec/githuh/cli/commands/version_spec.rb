# frozen_string_literal: true

require 'spec_helper'

require 'githuh'
require 'aruba/rspec'

RSpec.describe Githuh::CLI::Commands::Version, type: :aruba do
  context 'githuh version' do
    subject { output }

    let(:args) { %w(version) }

    include_context 'aruba setup'

    it { is_expected.not_to match /Githuh/ }
    it { is_expected.to match /#{Githuh::VERSION}/ }
  end
end
