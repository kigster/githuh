# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::User::Info, type: :aruba do
  context 'user info' do
    subject { output }

    let(:args) { %w(user info --help) }

    include_context 'aruba setup'

    it { is_expected.to match /Usage/ }
    it { is_expected.to match /Command:/ }
  end
end
