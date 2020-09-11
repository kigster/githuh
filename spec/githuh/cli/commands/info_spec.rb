# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::User::Info, type: :aruba do

  context 'user info' do
    let(:args) { %w(user info --help) }
    include_context 'aruba setup'

    subject { output }

    it { should match /Usage/ }
    it { should match /Command:/ }
  end
end
