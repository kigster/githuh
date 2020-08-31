#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby
require 'bundler/setup'
require 'dry/cli'
require 'json'
require 'tty/progressbar'

require_relative '../base'

module Githuh
  module CLI
    module Commands
      module Repo
        class List < Base
          FORMATS = {
            markdown: 'md',
            json:     'json'
          }.freeze

          DEFAULT_FORMAT        = :markdown
          DEFAULT_OUTPUT_FORMAT = "<username>.repositories.<format>"
          FORK_OPTIONS          = %w(exclude include only).freeze

          attr_accessor :filename, :file, :output, :repos, :format, :forks, :private, :record_count

          desc "List owned repositories and render the output in markdown or JSON\n" \
               "  Default output file is " + DEFAULT_OUTPUT_FORMAT.bold.yellow

          option :file, required: false, desc: 'Output file, overrides ' + DEFAULT_OUTPUT_FORMAT
          option :format, values: FORMATS.keys, default: DEFAULT_FORMAT.to_s, required: false, desc: 'Output format'
          option :forks, type: :string, values: FORK_OPTIONS, default: FORK_OPTIONS.first, required: false, desc: 'Include or exclude forks'
          option :private, type: :boolean, default: nil, required: false, desc: 'If specified, returns only private repos for true, public for false'

          def call(file: nil, format: nil, forks: nil, private: nil, **opts)
            super(**opts)

            self.record_count = 0
            self.forks        = forks
            self.private      = private
            self.repos        = []
            self.output       = StringIO.new
            self.format       = (format || DEFAULT_FORMAT).to_sym

            self.filename = file || "#{user_info.login}.repositories.#{FORMATS[self.format]}"
            self.file     = File.open(filename, 'w')

            puts
            puts TTY::Box.info("Format : #{self.format}\n" \
                               "File   : #{filename}\n" \
                               "Forks  : #{self.forks}\n",
                               width:   ui_width,
                               padding: 1)
            puts
            # —————————— actually get all repositories ———————————————
            self.file.write send("render_as_#{format}", repositories)
            # ————————————————————————————————————————————————————————

            puts
            puts TTY::Box.info("Success: written a total of #{record_count} records to #{filename}",
                               width: ui_width, padding: 1)
            puts
          ensure
            file.close if file.respond_to?(:close) && !file.closed?
          end

          def repositories
            page = 0
            bar = nil

            [].tap do |repo_list|
              loop do
                options = {
                  page:     page,
                  per_page: per_page,
                  type:     :owner,
                }

                result = client.repos({}, query: options)
                bar    = create_progress_bar if info && !verbose && page == 0

                bar&.advance
                filter_result!(result)

                break if result.empty?

                result.each { |repo| printf "%s\n", repo.name } if verbose

                repo_list << result

                page += 1

                self.record_count += result.size
              end

              bar&.finish; puts
            end.flatten.sort_by(&:stargazers_count).reverse.uniq(&:name)
          end

          def create_progress_bar
            number_of_pages = client.last_response.rels[:last].href.match(/page=(\d+).*$/)[1]
            TTY::ProgressBar.new("[:bar]",
                                 title:    'Fetching Repositories',
                                 total:    number_of_pages.to_i,
                                 width:    ui_width - 2,
                                 head:     '',
                                 complete: '▉'.magenta)
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

          private

          def filter_result!(result)
            result.reject! do |r|
              fork_reject = case forks
                            when 'exclude'
                              r.fork
                            when 'only'
                              !r.fork
                            when 'include'
                              false
                            end

              private_reject = case private
                               when true
                                 !r.private
                               when false
                                 r.private
                               when nil
                                 false
                               end

              fork_reject || private_reject
            end
          end
        end
      end

      register 'repo', aliases: ['r'] do |prefix|
        prefix.register 'list', Repo::List
      end
    end
  end
end
