# frozen_string_literal: true

require 'dry/cli'
require 'forwardable'
require 'tty/box'

require 'githuh'
module Githuh
  module CLI
    class Launcher
      attr_accessor :argv, :stdin, :stdout, :stderr, :kernel, :command

      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = nil)
        if ::Githuh.launcher
          raise(ArgumentError, "Another instance of CLI Launcher was detected, aborting.")
        else
          Githuh.launcher = self
        end

        self.argv   = argv
        self.stdin  = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.kernel = kernel
      end

      def execute!
        if argv.empty? || !(%w(--help -h) & argv).empty?
          stdout.puts BANNER
          Githuh.configure_kernel_behavior! help: true
        else
          Githuh.configure_kernel_behavior!
        end

        self.command = ::Dry::CLI.new(::Githuh::CLI::Commands)
        command.call(arguments: argv, out: stdout, err: stderr)

      rescue StandardError => e
        box = TTY::Box.frame('ERROR:', ' ', e.message, **BOX_OPTIONS)
        stderr.print box

      ensure
        Githuh.restore_kernel_behavior!
        exit(10) unless Githuh.in_test
      end
    end

    BANNER = <<~BANNER

      #{'Githuh CLI'.bold.yellow} #{::Githuh::VERSION.bold.green} — API client for Github.com.
      #{'© 2020 Konstantin Gredeskoul, All rights reserved.  MIT License.'.cyan}

    BANNER

    BOX_OPTIONS = {
      padding: 1,
      align:   :left,
      title:   { top_center: Githuh::BANNER },
      width:   80,
      style:   {
        bg:     :red,
        border: {
          fg: :bright_yellow,
          bg: :red
        }
      }
    }.freeze

  end
end
