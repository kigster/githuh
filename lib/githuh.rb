#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby

require 'octokit'
require 'colored2'

module Githuh
  VERSION = '0.1.0'

  module CLI
    module Commands
      extend Dry::CLI::Registry
    end
  end
end

require 'githuh/cli/commands/base'
require 'githuh/cli/commands/user/info'
require 'githuh/cli/commands/version'
require 'githuh/cli/commands/repo/list'
