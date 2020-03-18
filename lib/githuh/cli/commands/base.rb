# frozen_string_literal: true

require 'tty/box'
require 'stringio'
require 'githuh/version'
require 'forwardable'

module Githuh
  module CLI
    module Commands
      DEFAULT_PAGE_SIZE = 20

      class Base < Dry::CLI::Command
        extend Forwardable

        def_delegators :context, :stdout, :stderr, :stdin, :kernel, :argv

        class << self
          def inherited(base)
            super
            base.instance_eval do
              option :api_token, required: false, desc: "Github API token; if not given, user.token is read from ~/.gitconfig"
              option :per_page, required: false, default: DEFAULT_PAGE_SIZE, desc: "Pagination page size for Github API"
              option :info, type: :boolean, default: true, desc: 'Print UI elements, like a the progress bar'
              option :verbose, type: :boolean, default: false, desc: 'Print additional debugging info'
            end
          end
        end

        attr_accessor :client, :token, :per_page, :verbose, :info, :box, :context

        def call(api_token: nil,
                 per_page: DEFAULT_PAGE_SIZE,
                 verbose: false,
                 info: true)

          self.context  = Githuh
          self.verbose  = verbose
          self.info     = info
          self.token    = api_token || token_from_gitconfig
          self.per_page = per_page || DEFAULT_PAGE_SIZE
          self.client   = Octokit::Client.new(access_token: token)

          print_userinfo if info
        end

        protected

        def puts(*args)
          stdout.puts(*args)
        end

        def warn(*args)
          stderr.puts(*args)
        end

        def user_info
          @user_info ||= client.user
        end

        def ui_width
          80
        end

        private

        def print_userinfo
          duration = DateTime.now - DateTime.parse(user_info[:created_at].to_s)
          years    = (duration / 365).to_i
          months   = ((duration - years * 365) / 30).to_i
          days     = (duration - years * 365 - months * 30).to_i

          lines = []
          lines << sprintf("  Github API Token: %s", h("#{token[0..9]}#{'.' * 20}#{token[-11..-1]}"))
          lines << sprintf("      Current User: %s", h(user_info.login))
          lines << sprintf("      Public Repos: %s", h(user_info.public_repos.to_s))
          lines << sprintf("         Followers: %s", h(user_info.followers.to_s))
          lines << sprintf("        Member For: %s", h(sprintf("%d years, %d months, %d days", years, months, days)))

          self.box = TTY::Box.frame *lines,
                                    padding: 1,
                                    width:   ui_width,
                                    align:   :left,
                                    title:   { top_center: Githuh::BANNER },
                                    style:   {
                                      fg:     :white,
                                      border: {
                                        fg: :bright_green
                                      }
                                    }

          Githuh.stdout.print box
        end

        def h(arg)
          arg.to_s.bold.blue
        end

        def token_from_gitconfig
          @token_from_gitconfig ||= `git config --global --get user.token`.chomp

          return @token_from_gitconfig unless @token_from_gitconfig.empty?

          raise "No token was found in your ~/.gitconfig.\n" \
                "To add, run the following command: \n" \
                "git config --global --set user.token YOUR_GITHUB_TOKEN"
        end
      end
    end
  end
end
