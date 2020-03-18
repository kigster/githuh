# frozen_string_literal: true

require 'spec_helper'

require 'githuh'
require 'aruba/rspec'

RSpec.describe 'Githuh::CLI::Commands', type: :aruba do
  include_context 'aruba setup'

  context '--help' do
    let(:args) { %w(--help) }
    subject { output }
    it { should match /Githuh/ }
    it { should match /#{Githuh::VERSION}/ }
    it { should match /MIT License/ }
  end
end
