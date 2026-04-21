# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::Repo::List, type: :aruba do
  context 'repo list --help' do
    subject { output }

    let(:args) { %w(repo list -h) }

    include_context 'aruba setup'

    it { is_expected.to match /Usage/ }
    it { is_expected.to match /repo list/ }
  end
end
