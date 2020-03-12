# frozen_string_literal: true

module Githuh
  module CLI
    module Commands
      DEFAULT_PAGE_SIZE = 50

      class Base < Dry::CLI::Command
        class << self
          def inherited(base)
            super
            base.instance_eval do
              option :api_token, required: false, desc: "Github API token; if not given, user.token is read from ~/.gitconfig"
              option :per_page, required: false, default: DEFAULT_PAGE_SIZE, desc: "Pagination page size for Github API"
              option :verbose, type: :boolean, default: true, desc: 'Print verbose info'

            end
          end
        end

        attr_accessor :client, :token, :per_page, :verbose

        def call(api_token: nil,
                 per_page: DEFAULT_PAGE_SIZE,
                 verbose: true)

          self.verbose  = verbose
          self.token    = api_token || token_from_gitconfig
          self.per_page = per_page || DEFAULT_PAGE_SIZE
          self.client   = Octokit::Client.new(access_token: token)
        end

        private

        def token_from_gitconfig
          `git config --global --get user.token`.chomp
        end
      end
    end
  end
end
