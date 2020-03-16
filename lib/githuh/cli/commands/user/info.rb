#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby
require "bundler/setup"
require "dry/cli"
require_relative '../base'
require 'awesome_print'
require 'json'

module Githuh
  module CLI
    module Commands
      module User
        class Info < Base
          desc "Print user information"

          def call(**opts)
            super(**opts)
            ap client.user.to_hash
          end
        end
      end

      register "user", aliases: ["u"] do |prefix|
        prefix.register "info", User::Info
      end
    end
  end
end
