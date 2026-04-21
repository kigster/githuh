# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::Issue::Export, type: :aruba do
  subject { output }

  let(:labels) { [Hashie::Mash.new(name: 'bug'), Hashie::Mash.new(name: 'small')] }
  let(:issue_user) { Hashie::Mash.new(login: 'alice') }
  let(:issue) do
    Hashie::Mash.new(id:         42,
                     title:      'First issue',
                     body:       'Something broke',
                     html_url:   'https://github.com/rails/rails/issues/42',
                     labels:     labels,
                     user:       issue_user,
                     created_at: Time.now)
  end
  let(:issues) { [issue] }

  context 'issue export --help' do
    let(:args) { %w(issue export --help) }

    include_context 'aruba setup'

    it { is_expected.to match(/Usage/) }
    it { is_expected.to match(/Export Repo issues/) }
  end

  context 'issue export rails/rails --format=json' do
    let(:args) { %w(issue export rails/rails --format=json --api-token=abcdefghij0123456789 --no-info --no-verbose) }

    include_context 'aruba setup'

    it { is_expected.to match(/rails\.rails\.issues\.json/) }
    it { is_expected.to match(/Success/) }
    it { is_expected.to match(/Format : json/) }
  end

  context 'issue export with missing repo argument' do
    let(:args) { %w(issue export --api-token=abcdefghij0123456789 --no-info --no-verbose) }

    include_context 'aruba setup'

    it 'surfaces an error message' do
      expect(cmd.stderr).to match(/argument/i)
    end
  end

  describe '.issue_labels' do
    subject { described_class.issue_labels(issue) }

    it { is_expected.to eq(%w(bug small)) }
  end

  describe '.find_user' do
    let(:client) { double('client') }
    let(:alice) { Hashie::Mash.new(name: 'Alice A') }

    before do
      described_class.instance_variable_set(:@user_cache, nil)
      allow(client).to receive(:user).with('alice').and_return(alice)
    end

    it 'caches lookups by username' do
      expect(described_class.find_user(client, 'alice')).to eq('Alice A')
      described_class.find_user(client, 'alice')
      expect(client).to have_received(:user).once
    end
  end

  describe '#filter_issues' do
    subject(:command) { described_class.new }

    let(:pr) { Hashie::Mash.new(html_url: 'https://github.com/foo/bar/pull/1') }
    let(:bug) { Hashie::Mash.new(html_url: 'https://github.com/foo/bar/issues/1') }

    it { expect(command.filter_issues([pr, bug])).to eq([bug]) }
  end

  describe '#render_as_json' do
    subject(:command) { described_class.new }

    it 'renders issues as pretty JSON' do
      result = command.render_as_json([issue])
      parsed = JSON.parse(result)
      expect(parsed).to be_an(Array)
      expect(parsed.first['title']).to eq('First issue')
    end
  end

  describe '#render_as_csv' do
    subject(:command) do
      described_class.new.tap do |c|
        c.mapping = {}
        c.instance_variable_set(:@bar, double('bar', advance: true, finish: true))
        allow(c).to receive(:client).and_return(client)
      end
    end

    let(:alice) { Hashie::Mash.new(name: 'Alice A') }
    let(:client) { double('client', user: alice) }

    before do
      stub_const('Githuh::CLI::Commands::Issue::Export::LabelEstimates', {})
    end

    it 'renders a CSV with header and one data row' do
      csv = command.render_as_csv([issue])
      expect(csv).to match(/Id,Title,Labels/)
      expect(csv).to match(/Something broke/)
      expect(csv).to match(/Alice A/)
      expect(csv).to match(/bug,small/)
    end
  end
end
