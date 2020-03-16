# frozen_string_literal: true

require 'spec_helper'

require 'githuh'
require 'aruba/rspec'

RSpec.describe 'Githuh CLI', type: :aruba do
  let(:binary) { ::Githuh::BINARY }

  context "running the binary" do
    let(:args) { [] }
    let(:command) { "#{binary} #{args.join(' ')}" }

    before { run_command_and_stop(command) }

    let(:cmd) { last_command_started }
    let(:output) { cmd.stdout.chomp }

    subject { cmd  }

    context 'displaying usage' do
      context 'without any flags' do
        it { should have_exit_status(0) }
        describe 'its output' do
          subject { output }
          it { should match /Githuh/ }
        end
      end

      context '-h and --help' do
        let(:args) { %w(-h) }
        subject { output }

        it { should match /Githuh/ }
        it { should include Githuh::VERSION }
      end
    end
  end
end
