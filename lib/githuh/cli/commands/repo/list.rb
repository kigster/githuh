#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby
require 'bundler/setup'
require 'dry/cli'
require 'json'

require_relative '../base'

module Githuh
  module CLI
    module Commands
      module Repo
        class List < Base
          FORMATS      = %w(markdown json).freeze
          FORK_OPTIONS = %w(include only exclude).freeze

          attr_accessor :file, :output, :repos, :format, :forks

          desc 'List owned repositories and render the output in markdown or JSON'

          option :file, required: false, desc: 'Output file. If not provided, STDERR is used.'
          option :format, values: FORMATS, default: FORMATS.first, required: false, desc: 'Output format'
          option :forks, type: :string, values: FORK_OPTIONS, default: FORK_OPTIONS.first, required: false, desc: 'Include or exclude forks'

          def call(file: nil, format: nil, forks: nil, **opts)
            super(**opts)

            self.forks  = forks
            self.format = (format || FORMATS.first).to_sym
            self.repos  = []
            self.output = StringIO.new
            self.file   = STDOUT
            self.file   = file ? File.open(file, 'w') : STDERR

            self.file.write send("render_as_#{format}", repositories)
          ensure
            file.close if file.respond_to?(:close) && !file.closed?
          end

          private

          def repositories
            page = 0
            [].tap do |repo_list|
              loop do
                print '.'.green if verbose
                options = {
                    page:     page,
                    per_page: per_page,
                    type:     :owner,
                }

                result = client.repos({}, query: options)
                result.reject! do |r|
                  case forks
                    when 'exclude'
                      r.fork
                    when 'only'
                      !r.fork
                    when 'include'
                      false
                  end
                end
                break if result.empty?

                result.size.times { print '.'.green } if verbose

                repo_list << result
                page += 1
              end
              puts "  ✓".bold.green if verbose
            end.flatten.sort_by(&:stargazers_count).reverse.uniq(&:name)
          end

          def render_as_markdown(repositories)
            output.puts "### #{client.user.name}'s Repos\n"
            repositories.each_with_index do |repo, index|
              output.puts repo_as_markdown(index, repo)
            end
            output.string
          end

          def render_as_json(repositories)
            JSON.pretty_generate(repositories.map(&:to_hash))
          end

          def repo_as_markdown(index, repo)
            <<~REPO

              ### #{index + 1}. [#{repo.name}](#{repo.url}) (#{repo.stargazers_count} ★)

              #{repo.language ? "**#{repo.language}**. " : ''}
              #{repo.license ? "Distributed under the **#{repo.license.name}** license." : ''}

              #{repo.description}

            REPO
          end
        end
      end

      register 'repo', aliases: ['r'] do |prefix|
        prefix.register 'list', Repo::List
      end
    end
  end
end
