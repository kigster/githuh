# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::User::Info, type: :aruba do
  subject { output }

  context 'user info --help' do
    let(:args) { %w(user info --help) }

    include_context 'aruba setup'

    it { is_expected.to match(/Usage/) }
    it { is_expected.to match(/Command:/) }
  end

  context 'user info with --api-token' do
    let(:args) { %w(user info --api-token=abcdefghij0123456789) }

    include_context 'aruba setup'

    it { is_expected.to match(/john/) }
    it { is_expected.to match(/Github API Token/) }
    it { is_expected.to match(/Current User/) }
    it { is_expected.to match(/Public Repos/) }
  end

  context 'user info with --no-info (skips userinfo box)' do
    let(:args) { %w(user info --api-token=abcdefghij0123456789 --no-info) }

    include_context 'aruba setup'

    it { is_expected.to match(/john/) }
    it { is_expected.not_to match(/Github API Token/) }
  end
end
