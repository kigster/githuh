# frozen_string_literal: true

require 'dry/cli'
require 'forwardable'
require 'tty/box'
require 'tty/screen'

require 'githuh'
require 'githuh/cli/commands/base'

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

        # noinspection RubyYardParamTypeMatch
        self.command = ::Dry::CLI.new(::Githuh::CLI::Commands)
        command.call(arguments: argv, out: stdout, err: stderr)
      rescue StandardError => e
        lines = [e.message.gsub(/\n/, ', ')]
        if e.backtrace && !((ARGV & %w[-v --verbose]).empty?)
          lines << ''
          lines.concat(e.backtrace)
        end

        box = TTY::Box.frame(*lines,
                             **BOX_OPTIONS.merge(
                               width: TTY::Screen.width,
                               title: { top_center: "┤ #{e.class.name} ├" },
                             ))
        stderr.puts
        stderr.print box
      ensure
        Githuh.restore_kernel_behavior!
        exit(0) unless Githuh.in_test
      end

      def trace?
        argv.include?('-t') || argv.include?('--trace')
      end
    end

    BANNER = <<~BANNER

      #{'Githuh CLI'.bold.yellow} #{::Githuh::VERSION.bold.green} — API client for Github.com.
      #{'© 2020 Konstantin Gredeskoul, All rights reserved.  MIT License.'.cyan}

    BANNER

    BOX_OPTIONS = {
      padding: 1,
      align:   :left,
      title:   { top_center: "┤ #{Githuh::BANNER} ├" },
      width:   80,
      style:   {
        bg:     :yellow,
        fg:     :black,
        border: {
          fg: :red,
          bg: :yellow
        }
      }
    }.freeze
  end
end
