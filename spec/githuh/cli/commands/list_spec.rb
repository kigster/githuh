# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Commands::Repo::List, type: :aruba do
  subject { output }

  context 'repo list --help' do
    let(:args) { %w(repo list -h) }

    include_context 'aruba setup'

    it { is_expected.to match(/Usage/) }
    it { is_expected.to match(/repo list/) }
  end

  context 'repo list --format=markdown' do
    let(:args) { %w(repo list --format=markdown --api-token=abcdefghij0123456789 --no-info --no-verbose) }

    include_context 'aruba setup'

    it { is_expected.to match(/john\.repositories\.md/) }
    it { is_expected.to match(/Format : markdown/) }
    it { is_expected.to match(/Success/) }
  end

  context 'repo list --format=json' do
    let(:args) { %w(repo list --format=json --api-token=abcdefghij0123456789 --no-info --no-verbose) }

    include_context 'aruba setup'

    it { is_expected.to match(/john\.repositories\.json/) }
    it { is_expected.to match(/Success/) }
  end

  describe '#render_as_markdown' do
    subject(:command) { described_class.new.tap { |c| c.output = StringIO.new } }

    let(:user) { Hashie::Mash.new(name: 'John') }
    let(:client) { double('client', user: user) }
    let(:repos) do
      [Hashie::Mash.new(name:             'kigster/githuh',
                        url:              'https://github.com/kigster/githuh',
                        stargazers_count: 2,
                        language:         'Ruby',
                        license:          { name: 'MIT' },
                        description:      'Test gem')]
    end

    before { allow(command).to receive(:client).and_return(client) }

    it 'renders the repos as a markdown list' do
      md = command.render_as_markdown(repos)
      expect(md).to match(/### John's Repos/)
      expect(md).to match(%r{kigster/githuh})
      expect(md).to match(/\*\*Ruby\*\*/)
      expect(md).to match(/MIT.*license/)
      expect(md).to match(/Test gem/)
    end

    context 'when llm_adapter is configured' do
      let(:llm) { instance_double(Githuh::LLM::Anthropic) }
      let(:readme_content) { Base64.strict_encode64('# kigster/githuh\n\nA cool tool') }

      before do
        command.llm_adapter = llm
        allow(client).to receive(:readme).with('kigster/githuh').and_return(
          Hashie::Mash.new(content: readme_content)
        )
      end

      it 'replaces the repo description with an LLM summary' do
        allow(llm).to receive(:summarize).and_return('LLM-generated summary of the repo.')
        md = command.render_as_markdown(repos)
        expect(md).to include('LLM-generated summary of the repo.')
        expect(md).not_to include('Test gem')
      end

      it 'falls back to the original description on LLM error' do
        allow(llm).to receive(:summarize).and_raise(Githuh::LLM::Error, 'nope')
        md = command.render_as_markdown(repos)
        expect(md).to include('Test gem')
      end

      it 'falls back when README fetch fails' do
        allow(client).to receive(:readme).and_raise(StandardError, 'not found')
        md = command.render_as_markdown(repos)
        expect(md).to include('Test gem')
      end
    end
  end

  describe '#build_llm_adapter' do
    subject(:command) { described_class.new.tap { |c| c.info = false; c.verbose = false } }

    it 'raises when no API key is set' do
      allow(Githuh::LLM).to receive(:build).and_return(nil)
      expect { command.build_llm_adapter }.to raise_error(Githuh::LLM::Error, /ANTHROPIC_API_KEY/)
    end

    it 'returns the adapter when one is available' do
      adapter = instance_double(Githuh::LLM::Anthropic, class: Githuh::LLM::Anthropic)
      allow(Githuh::LLM).to receive(:build).and_return(adapter)
      expect(command.build_llm_adapter).to eq(adapter)
    end
  end

  describe 'LLM announcement', type: :aruba do
    let(:args) { %w(repo list --llm --format=json --api-token=abcdefghij0123456789 --no-verbose) }

    before do
      allow(Githuh::LLM).to receive(:build)
                              .and_return(instance_double(Githuh::LLM::Anthropic, class: Githuh::LLM::Anthropic))
    end

    include_context 'aruba setup'

    it 'prints an info box announcing LLM summarization' do
      expect(output).to match(/LLM summaries: ENABLED/)
      expect(output).to match(/Provider\s*: Anthropic/)
      expect(output).to match(/summarized/)
    end
  end

  describe 'LLM with no key available', type: :aruba do
    let(:args) { %w(repo list --llm --format=json --api-token=abcdefghij0123456789 --no-verbose) }

    before { allow(Githuh::LLM).to receive(:build).and_return(nil) }

    include_context 'aruba setup'

    it 'errors out with a clear message on stderr' do
      expect(cmd.stderr).to match(/ANTHROPIC_API_KEY/)
    end
  end

  describe '#render_as_json' do
    subject(:command) { described_class.new }

    let(:repos) { [Hashie::Mash.new(name: 'foo', stars: 5)] }

    it 'renders the repos as pretty JSON' do
      json = command.render_as_json(repos)
      parsed = JSON.parse(json)
      expect(parsed).to eq([{ 'name' => 'foo', 'stars' => 5 }])
    end
  end

  describe '#filter_result! (private)' do
    subject(:command) { described_class.new }

    let(:mit) { Hashie::Mash.new(name: 'mit', fork: false, private: false) }
    let(:forked) { Hashie::Mash.new(name: 'fork', fork: true, private: false) }
    let(:privy) { Hashie::Mash.new(name: 'priv', fork: false, private: true) }

    def filter(list, forks:, private: nil)
      command.forks = forks
      command.private = private
      command.send(:filter_result!, list)
      list
    end

    it 'excludes forks when forks=exclude' do
      list = [mit, forked]
      expect(filter(list, forks: 'exclude')).to eq([mit])
    end

    it 'keeps only forks when forks=only' do
      list = [mit, forked]
      expect(filter(list, forks: 'only')).to eq([forked])
    end

    it 'keeps everything when forks=include' do
      list = [mit, forked]
      expect(filter(list, forks: 'include')).to eq([mit, forked])
    end

    it 'keeps only private repos when private=true' do
      list = [mit, privy]
      expect(filter(list, forks: 'include', private: true)).to eq([privy])
    end

    it 'keeps only public repos when private=false' do
      list = [mit, privy]
      expect(filter(list, forks: 'include', private: false)).to eq([mit])
    end
  end
end
