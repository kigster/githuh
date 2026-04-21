#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby
require 'bundler/setup'
require 'dry/cli'
require 'base64'
require 'json'
require 'tty/progressbar'

require_relative '../base'
require_relative '../../../llm'

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

          attr_accessor :filename, :file, :output, :repos, :format,
                        :forks, :private, :record_count, :llm_adapter

          desc "List owned repositories and render the output in markdown or JSON\n  " \
               "Default output file is " + DEFAULT_OUTPUT_FORMAT.bold.yellow

          option :file,
                 required: false,
                 desc:     "Output file, overrides #{DEFAULT_OUTPUT_FORMAT}"

          option :format,
                 values:   FORMATS.keys,
                 default:  DEFAULT_FORMAT.to_s,
                 required: false,
                 desc:     'Output format'

          option :forks, type:     :string,
                         values:   FORK_OPTIONS,
                         default:  FORK_OPTIONS.first,
                         required: false,
                         desc:     'Include or exclude forks'

          option :private,
                 type:     :boolean,
                 default:  nil,
                 required: false,
                 desc:     'If specified, returns only private repos for true, public for false'

          option :llm,
                 type:     :boolean,
                 default:  false,
                 required: false,
                 desc:     'Use LLM (ANTHROPIC_API_KEY or OPENAI_API_KEY) to summarize README'

          def call(file: nil, format: nil, forks: nil, private: nil, llm: false, **)
            super(**)

            self.record_count = 0
            self.forks        = forks
            self.private      = private
            self.repos        = []
            self.output       = StringIO.new
            self.format       = (format || DEFAULT_FORMAT).to_sym
            self.llm_adapter  = build_llm_adapter if llm

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
            bar  = nil

            [].tap do |repo_list|
              loop do
                options = {
                  page:     page,
                  per_page: per_page,
                  type:     :owner,
                }

                result = client.repos({}, query: options)
                bar('Repositories')&.advance

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

          def bar_size
            return 1 if client&.last_response.nil?

            client&.last_response&.rels&.[](:last)&.href&.match(/page=(\d+).*$/)&.[](1)&.to_i # rubocop:disable Style/SafeNavigationChainLength
          end

          def render_as_markdown(repositories)
            output.puts "### #{client.user.name}'s Repos\n"

            llm_bar = build_llm_progress_bar(repositories.size) if llm_adapter

            repositories.each_with_index do |repo, index|
              output.puts repo_as_markdown(index, repo)
              llm_bar&.advance
            end

            if llm_bar
              llm_bar.finish
              puts
            end

            output.string
          end

          def build_llm_progress_bar(total)
            return unless info || verbose

            color = llm_adapter.class.const_defined?(:BAR_COLOR) ? llm_adapter.class::BAR_COLOR : :cyan
            provider = llm_adapter.class.name.split('::').last

            puts
            puts " • Summarizing #{total} READMEs with #{provider}…".send(color)
            TTY::ProgressBar.new("[:bar]",
                                 title:    'LLM Summaries',
                                 total:    total,
                                 width:    ui_width - 2,
                                 head:     '',
                                 complete: '▉'.send(color))
          end

          def render_as_json(repositories)
            JSON.pretty_generate(repositories.map(&:to_hash))
          end

          def repo_as_markdown(index, repo)
            description = describe(repo)

            <<~REPO

              ### #{index + 1}. [#{repo.name}](#{repo.url}) (#{repo.stargazers_count} ★)

              #{"**#{repo.language}**. " if repo.language}
              #{"Distributed under the **#{repo.license.name}** license." if repo.license}

              #{description}

            REPO
          end

          def describe(repo)
            return repo.description unless llm_adapter

            readme = fetch_readme(repo)
            return repo.description if readme.nil? || readme.empty?

            llm_adapter.summarize(readme)
          rescue StandardError => e
            warn "LLM summary failed for #{repo_full_name(repo)}: #{e.message}" if verbose
            repo.description
          end

          def fetch_readme(repo)
            readme = client.readme(repo_full_name(repo))
            return nil unless readme

            encoded = readme.respond_to?(:content) ? readme.content : readme[:content]
            return nil if encoded.nil? || encoded.to_s.empty?

            Base64.decode64(encoded).force_encoding('UTF-8')
          rescue StandardError => e
            warn "README fetch failed for #{repo_full_name(repo)}: #{e.message}" if verbose
            nil
          end

          def repo_full_name(repo)
            repo.respond_to?(:full_name) && repo.full_name ? repo.full_name : repo.name
          end

          def build_llm_adapter
            adapter = Githuh::LLM.build
            raise Githuh::LLM::Error, '--llm was specified but neither ANTHROPIC_API_KEY nor OPENAI_API_KEY is set' unless adapter

            announce_llm(adapter) if info
            adapter
          end

          def announce_llm(adapter)
            provider = adapter.class.name.split('::').last
            model    = adapter.class.const_defined?(:MODEL) ? adapter.class::MODEL : 'n/a'

            puts
            puts TTY::Box.info(
              "LLM summaries: ENABLED\n" \
              "Provider     : #{provider}\n" \
              "Model        : #{model}\n" \
              "\n" \
              "For each repository, the README will be fetched and summarized\n" \
              "into a 5-6 sentence description before writing to the output file.",
              width: ui_width, padding: 1
            )
            puts
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
