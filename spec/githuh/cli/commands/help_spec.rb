# frozen_string_literal: true

require 'spec_helper'

require 'githuh'
require 'aruba/rspec'

RSpec.describe 'Githuh::CLI::Commands', type: :aruba do
  context '--help' do
    subject { output }

    let(:args) { %w(--help) }

    include_context 'aruba setup'

    it { is_expected.to match /Githuh/ }
    it { is_expected.to match /#{Githuh::VERSION}/ }
    it { is_expected.to match /MIT License/ }
  end
end
