# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::LLM do
  describe '.build' do
    before do
      ENV.delete('ANTHROPIC_API_KEY')
      ENV.delete('OPENAI_API_KEY')
    end

    context 'when neither key is set' do
      it { expect(described_class.build).to be_nil }
      it { expect(described_class.available?).to be false }
    end

    context 'when ANTHROPIC_API_KEY is set' do
      before { ENV['ANTHROPIC_API_KEY'] = 'sk-ant-test' }
      after { ENV.delete('ANTHROPIC_API_KEY') }

      it 'returns an Anthropic adapter' do
        expect(described_class.build).to be_a(Githuh::LLM::Anthropic)
      end
    end

    context 'when only OPENAI_API_KEY is set' do
      before { ENV['OPENAI_API_KEY'] = 'sk-test' }
      after { ENV.delete('OPENAI_API_KEY') }

      it 'returns an OpenAI adapter' do
        expect(described_class.build).to be_a(Githuh::LLM::OpenAI)
      end
    end

    context 'when both keys are set' do
      before do
        ENV['ANTHROPIC_API_KEY'] = 'sk-ant-test'
        ENV['OPENAI_API_KEY']    = 'sk-test'
      end

      after do
        ENV.delete('ANTHROPIC_API_KEY')
        ENV.delete('OPENAI_API_KEY')
      end

      it 'prefers Anthropic' do
        expect(described_class.build).to be_a(Githuh::LLM::Anthropic)
      end
    end

    context 'when key is empty/whitespace' do
      before { ENV['ANTHROPIC_API_KEY'] = '   ' }
      after { ENV.delete('ANTHROPIC_API_KEY') }

      it 'treats it as unset' do
        expect(described_class.build).to be_nil
      end
    end
  end

  describe Githuh::LLM::Anthropic do
    subject(:adapter) { described_class.new(api_key: 'sk-ant-test') }

    let(:success_body) do
      JSON.dump(content: [{ type: 'text', text: 'A concise repo summary.' }])
    end

    it 'POSTs to the messages endpoint and returns the text' do
      stub = instance_double(Net::HTTPOK, is_a?: true, code: '200', body: success_body)
      allow(adapter).to receive(:post_json).and_return(stub)

      expect(adapter.summarize('# My Repo')).to eq('A concise repo summary.')
    end

    it 'raises Githuh::LLM::Error on non-200' do
      stub = instance_double(Net::HTTPBadRequest, is_a?: false, code: '401', body: 'bad key')
      allow(adapter).to receive(:post_json).and_return(stub)

      expect { adapter.summarize('x') }.to raise_error(Githuh::LLM::Error, /401/)
    end
  end

  describe Githuh::LLM::OpenAI do
    subject(:adapter) { described_class.new(api_key: 'sk-test') }

    let(:success_body) do
      JSON.dump(choices: [{ message: { content: 'A tidy summary from OpenAI.' } }])
    end

    it 'POSTs to chat/completions and returns the text' do
      stub = instance_double(Net::HTTPOK, is_a?: true, code: '200', body: success_body)
      allow(adapter).to receive(:post_json).and_return(stub)

      expect(adapter.summarize('# My Repo')).to eq('A tidy summary from OpenAI.')
    end
  end

  describe Githuh::LLM::Base do
    let(:adapter) { described_class.new(api_key: 'k') }

    it 'truncates long READMEs in the prompt' do
      long = 'x' * 20_000
      prompt = adapter.send(:prompt_for, long)
      expect(prompt.length).to be < 13_000
      expect(prompt).to include('xxx')
    end
  end
end
