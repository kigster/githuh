#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby
require 'bundler/setup'
require 'dry/cli'
require 'json'
require 'tty/progressbar'
require 'csv'
require 'active_support/inflector'

require_relative '../base'

module Githuh
  module CLI
    module Commands
      module Issue
        class Export < Base
          FORMATS = {
            json: 'json',
            csv:  'csv'
          }.freeze

          DEFAULT_FORMAT        = :csv
          DEFAULT_OUTPUT_FORMAT = "<username>.<repo>.issues.<format>"

          attr_accessor :filename, :file, :output, :repo, :issues, :format, :record_count

          desc "Export Repo issues into a CSV or JSON format\n" \
               "  Default output file is " + DEFAULT_OUTPUT_FORMAT.bold.yellow

          argument :repo, type: :string, required: true, desc: 'Name of the repo, eg "rails/rails"'
          option :file, required: false, desc: 'Output file, overrides ' + DEFAULT_OUTPUT_FORMAT
          option :format, values: FORMATS.keys.map(&:to_s), default: DEFAULT_FORMAT.to_s, required: false, desc: 'Output format'

          def call(repo: nil, file: nil, format: nil, **opts)
            super(**opts)

            self.record_count = 0
            self.repo         = repo

            raise ArgumentError, "argument <repo> is required" unless repo
            raise ArgumentError, "argument <repo> is not a repository, expected eg 'rails/rails'" unless repo =~ %r{/}

            self.issues = []
            self.output = StringIO.new
            self.format = (format || DEFAULT_FORMAT).to_sym

            self.filename = file || file_name(repo)
            self.file     = File.open(filename, 'w')

            print_summary

            # —————————— actually get all issues ———————————————
            self.file.write send("render_as_#{format}", fetch_issues)
            # ————————————————————————————————————————————————————————

            print_conclusion
          ensure
            file.close if file.respond_to?(:close) && !file.closed?
          end

          def fetch_issues
            client.auto_paginate = true
            self.issues          = filter_issues(client.issues(repo, query: default_options)).tap do |issue_list|
              self.record_count = issue_list.size
              bar('Issues')&.advance
            end
          end

          def filter_issues(issues_list)
            issues_list.reject do |issue|
              issue.html_url =~ /pull/
            end
          end

          def bar_size
            record_count + 1
          end

          def default_options
            { state: 'open' }
          end

          def self.issue_labels(issue)
            issue.labels.map(&:name)
          end

          def self.find_user(client, username)
            @user_cache           ||= {}
            @user_cache[username] ||= client.user(username).name
          end

          CSV_MAP = {
            'Labels'        => ->(_client, issue) { issue_labels(issue).reject { |l| LABEL_ESTIMATES.key?(l) }.join(',').downcase },
            'Type'          => ->(*) { 'feature' },
            'Estimate'      => ->(_client, issue) do
              el = issue_labels(issue).find { |l| LABEL_ESTIMATES.key?(l) }
              el ? LABEL_ESTIMATES[el] : nil
            end,
            'Current State' => ->(*) { 'unstarted' },
            'Requested By'  => ->(client, issue) do
              find_user(client, issue.user.login)
            end,
            'Owned By'  => ->(client, issue) do
              find_user(client, issue.user.login)
            end,
            'Description'   => ->(_client, issue) {
              issue.body
            },
            'Created at'    => ->(_client, issue) { issue.created_at },
          }.freeze

          LABEL_ESTIMATES = {
            'XXL(13 eng day)' => 15,
            'XL(8 eng day)'   => 15,
            'xs(<=1 eng day)' => 3,
            'L(5 eng day)'    => 15,
            'm(3 eng day)'    => 9,
            's(2 eng day)'    => 6
          }.freeze

          CSV_HEADER = %w(Id Title Labels Type Estimate) +
            ['Current State', 'Created at', 'Accepted at', 'Deadline', 'Requested By',
             'Owned By', 'Description', 'Comment', 'Comment', 'Comment', 'Comment'].freeze

          # Id,Title,Labels,Type,Estimate,Current State,Created at,Accepted at,Deadline,Requested By,Owned By,Description,Comment,Comment
          # 100, existing started story,"label one,label two",feature,1,started,"Nov 22, 2007",,,user1,user2,this will update story 100,,
          # ,new story,label one,feature,-1,unscheduled,,,,user1,,this will create a new story in the icebox,comment1,comment2
          def render_as_csv(issue_list)
            # puts "rendering issues as CVS:"
            # pp issue_list
            ::CSV.generate do |csv|
              csv << CSV_HEADER
              issue_list.each do |issue|
                row = []
                CSV_HEADER.each do |column|
                  method = column.downcase.underscore.to_sym
                  value  = if CSV_MAP[column]
                    CSV_MAP[column][client, issue]
                  else
                    begin
                      issue.to_h[method]
                    rescue StandardError
                      nil
                    end
                  end
                  value  = value.strip if value.is_a?(String)
                  row << value
                end
                csv << row
                bar&.advance
              end
              bar.finish
            end
          end

          def render_as_json(issue_list)
            JSON.pretty_generate(issue_list.map(&:to_h))
          end

          private

          def print_conclusion
            puts
            puts TTY::Box.info("Success: written a total of #{record_count} records to #{filename}",
                               width: ui_width, padding: 1)
            puts
          end

          def print_summary
            puts
            puts TTY::Box.info("Format : #{self.format}\n" \
                               "File   : #{filename}\n" \
                               "Repo   : #{repo}\n",
                               width:   ui_width,
                               padding: 1)
            puts
          end

          def file_name(repo)
            "#{repo.gsub(%r{/}, '.')}.issues.#{FORMATS[self.format.to_sym]}"
          end
        end
      end

      register 'issue', aliases: ['r'] do |prefix|
        prefix.register 'export', Issue::Export
      end
    end
  end
end
