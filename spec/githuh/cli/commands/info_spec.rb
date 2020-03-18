# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::User::Info, type: :aruba do
  include_context 'aruba setup'

  context 'user info' do
    let(:args) { %w(user info --help) }

    subject { output }

    it { should match /Usage/ }
    it { should match /Command:/ }
  end
end
