# frozen_string_literal: true

RSpec.shared_context 'aruba setup', shared_context: :aruba_setup do
  let(:binary) { ::Githuh::BINARY }
  let(:args) { [] }
  let(:command) { "#{binary} #{args.join(' ')}" }

  before { run_command_and_stop(command) }

  let(:cmd) { last_command_started }
  let(:output) { cmd.stdout.chomp }

  subject { cmd }
end

RSpec.configure do |rspec|
  rspec.include_context 'aruba setup', include_shared: true
end
