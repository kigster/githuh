#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby

require 'octokit'
require 'colored2'
require 'dry/cli'

module Githuh
  VERSION = '0.1.0'

  module CLI
    module Commands
      extend Dry::CLI::Registry
    end

    class Launcher
      attr_accessor :argv, :stdin, :stdout, :stderr, :kernel

      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = nil)
        self.argv   = argv
        self.stdin  = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.kernel = kernel
      end

      def execute
        if argv.empty? || !(%w(--help -h) & argv).empty?
          stdout.puts <<~BANNER

            #{'Githuh CLI'.bold.yellow} #{::Githuh::VERSION.bold.green} — API client for Github.com.
            #{'© 2020 Konstantin Gredeskoul, All rights reserved.  MIT License.'.cyan}

          BANNER
        end
        ::Dry::CLI.new(Commands).call
      end
    end
  end
end

require 'githuh/cli/commands/base'
require 'githuh/cli/commands/user/info'
require 'githuh/cli/commands/version'
require 'githuh/cli/commands/repo/list'
