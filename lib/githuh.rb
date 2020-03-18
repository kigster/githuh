#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby

require 'octokit'
require 'colored2'
require 'dry/cli'
require 'forwardable'

require_relative 'githuh/version'

module Githuh
  BANNER  = "Githuh Version #{VERSION}"
  BINARY  = File.expand_path('../exe/githuh', __dir__).freeze

  module CLI
    module Commands
      extend Dry::CLI::Registry
    end
  end
end

require 'githuh/cli/launcher'

module Githuh
  class << self
    attr_accessor :launcher, :in_test

    extend Forwardable

    def_delegators :launcher, :stdout, :stderr, :stdin, :kernel, :argv

    def configure_kernel_behavior!(help: false)
      Kernel.module_eval do
        alias original_exit exit
        alias original_puts puts
        alias original_warn warn
      end

      Kernel.module_eval do
        def puts(*args)
          ::Githuh.stdout.puts(*args)
        end

        def warn(*args)
          ::Githuh.stderr.puts(*args)
        end
      end

      if in_test
        Kernel.module_eval do
          def exit(code)
            ::Githuh.stderr.puts("RSpec: intercepted exit code: #{code}")
          end
        end
      elsif help
        Kernel.module_eval do
          def exit(_code)
            # for help, override default exit code with 0
            original_exit(0)
          end
        end
      else
        Kernel.module_eval do
          def exit(code)
            original_exit(code)
          end
        end
      end

      Dry::CLI
    end

    def restore_kernel_behavior!
      Kernel.module_eval do
        alias exit original_exit
        alias puts original_puts
        alias warn original_warn
        alias exit original_exit
      end
    end
  end
end

require 'githuh/cli/commands/base'
require 'githuh/cli/commands/user/info'
require 'githuh/cli/commands/version'
require 'githuh/cli/commands/repo/list'
