# frozen_string_literal: true

require 'hashie/mash'

def load_aruba!
  RSpec.shared_context 'aruba setup', shared_context: :aruba_setup do
    let(:binary) { ::Githuh::BINARY }
    let(:command) { "#{binary} #{args.join(' ')}" }
    let(:repos) {
      [
        Hashie::Mash.new({
                           stargazers_count: 2,
                           name:             'kigster/githuh',
                           url:              'https://github.com/kigster/githuh'
                         })
      ]
    }

    let(:user) do
      Hashie::Mash.new({ name:       'John',
                         created_at: Time.now,
                         login:      'john',
                         repos:      repos })
    end

    before do
      @mock_client = double("client", user: user, repos: repos, last_response: nil)
      allow_any_instance_of(Githuh::CLI::Commands::Base).to receive(:client).and_return(@mock_client)
      allow_any_instance_of(Githuh::CLI::Commands::Base).to receive(:user_info).and_return(user)
      allow_any_instance_of(Githuh::CLI::Commands::Issue::Export).to receive(:client).and_return(@mock_client)
      allow_any_instance_of(Githuh::CLI::Commands::Repo::List).to receive(:client).and_return(@mock_client)
      allow_any_instance_of(Githuh::CLI::Commands::Repo::List).to receive(:repositories).and_return(repos)
    end

    before { run_command_and_stop(command) }

    let(:cmd) { last_command_started }
    let(:output) { cmd.stdout.chomp }

    subject { cmd }
  end

  RSpec.configure do |rspec|
    rspec.include_context 'aruba setup', include_shared: true
  end
end
