# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Githuh::CLI::Launcher, type: :aruba do
  describe 'no arguments shows banner' do
    subject { output }

    let(:args) { [] }

    include_context 'aruba setup'

    it { is_expected.to match(/Githuh CLI/) }
    it { is_expected.to match(/#{Githuh::VERSION}/) }
    it { is_expected.to match(/MIT License/) }
  end

  describe 'direct invocation' do
    let(:stdin)  { StringIO.new }
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }

    after { Githuh.launcher = nil }

    describe '#trace?' do
      it 'returns true when -t is present' do
        launcher = described_class.new(%w(foo -t), stdin, stdout, stderr)
        expect(launcher.trace?).to be true
      end

      it 'returns true when --trace is present' do
        launcher = described_class.new(%w(foo --trace), stdin, stdout, stderr)
        expect(launcher.trace?).to be true
      end

      it 'returns false otherwise' do
        launcher = described_class.new(%w(foo), stdin, stdout, stderr)
        expect(launcher.trace?).to be false
      end
    end

    describe 'duplicate launcher guard' do
      it 'raises ArgumentError when a launcher is already set' do
        described_class.new([], stdin, stdout, stderr)
        expect { described_class.new([], stdin, stdout, stderr) }
          .to raise_error(ArgumentError, /Another instance/)
      end
    end

    describe 'error box rendering' do
      it 'wraps exceptions raised by commands in a TTY::Box on stderr' do
        allow_any_instance_of(Githuh::CLI::Commands::User::Info)
          .to receive(:call).and_raise(StandardError, 'kaboom')

        launcher = described_class.new(%w(user info --api-token=abcdefghij0123456789), stdin, stdout, stderr)
        launcher.execute!

        expect(stderr.string).to match(/kaboom/)
        expect(stderr.string).to match(/StandardError/)
      end

      it 'includes backtrace with --verbose' do
        allow_any_instance_of(Githuh::CLI::Commands::User::Info)
          .to receive(:call).and_raise(StandardError, 'kaboom')

        launcher = described_class.new(%w(user info --verbose), stdin, stdout, stderr)
        launcher.execute!

        expect(stderr.string).to match(/kaboom/)
      end
    end
  end
end
