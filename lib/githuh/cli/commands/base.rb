# frozen_string_literal: true

require 'tty/box'
require 'stringio'
require 'githuh/version'
require 'forwardable'

module Githuh
  module CLI
    module Commands
      DEFAULT_PAGE_SIZE = 20
      DEFAULT_TITLE     = 'Operation Progress'

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

        attr_accessor :token, :per_page, :verbose, :info, :box, :context

        def call(api_token: nil,
                 per_page: DEFAULT_PAGE_SIZE,
                 verbose: false,
                 info: true)

          self.context  = Githuh
          self.verbose  = verbose
          self.info     = info
          self.token    = api_token || determine_github_token
          self.per_page = per_page.to_i || DEFAULT_PAGE_SIZE

          if info
            begin
              print_userinfo
            rescue StandardError
              nil
            end
          end
        end

        def client
          @client ||= Octokit::Client.new(access_token: token)
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

        def bar(title = DEFAULT_TITLE)
          @bar ||= create_progress_bar(title: title)
        end

        # Overwrite me
        def bar_size
          0
        end

        def create_progress_bar(size = bar_size, title: DEFAULT_TITLE)
          return unless info || verbose

          TTY::ProgressBar.new("[:bar]",
                               title:    title,
                               total:    size.to_i,
                               width:    ui_width - 2,
                               head:     '',
                               complete: '▉'.magenta)
        end

        def determine_github_token
          @github_token ||= (ENV['GITHUB_TOKEN'] || `git config --global --get user.token`.chomp)

          return @github_token unless @github_token.empty?

          raise "No token was found in your ~/.gitconfig.\n" \
                "To add, run the following command: \n" \
                "git config --global --set user.token YOUR_GITHUB_TOKEN\n" \
                "or set environment variable GITHUB_TOKEN"
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

          self.box = TTY::Box.frame(*lines,
                                    padding: 0,
                                    width:   ui_width,
                                    align:   :left,
                                    title:   { top_center: "┤ #{Githuh::BANNER} ├" },
                                    style:   {
                                      fg:     :white,
                                      border: {
                                        fg: :bright_green
                                      }
                                    })

          Githuh.stdout.print box
        end

        def h(arg)
          arg.to_s
        end
      end
    end
  end
end
