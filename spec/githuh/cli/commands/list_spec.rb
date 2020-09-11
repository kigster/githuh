# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::Repo::List, type: :aruba do
  context 'repo list --help' do
    let(:args) { %w(repo list -h) }
    include_context 'aruba setup'
    subject { output }

    it { should match /Usage/ }
    it { should match /repo list/ }
  end
end
