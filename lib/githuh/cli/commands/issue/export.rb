#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: ft=ruby
require 'bundler/setup'
require 'dry/cli'
require 'json'
require 'tty/progressbar'
require 'csv'

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
          DEFAULT_OUTPUT_FORMAT = "<username>.<repo>-issues.<format>"

          attr_accessor :filename, :file, :output, :repo, :issues, :format, :record_count

          desc "Export repo issues into a CSV or JSON format\n" \
               "  Default output file is " + DEFAULT_OUTPUT_FORMAT.bold.yellow

          option :repo, required: true, desc: 'Name of the repo, eg "rails/rails"'
          option :file, required: false, desc: 'Output file, overrides ' + DEFAULT_OUTPUT_FORMAT
          option :format, values: FORMATS.keys, default: DEFAULT_FORMAT.to_s, required: false, desc: 'Output format'

          def call(file: nil, format: nil, repo: nil, **opts)
            super(**opts)

            self.record_count = 0
            self.repo         = repo
            raise "--repo argument is required" unless repo
            self.issues       = []
            self.output       = StringIO.new
            self.format       = (format || DEFAULT_FORMAT).to_sym

            self.filename = file || file_name(repo)
            self.file     = File.open(filename, 'w')

            puts
            puts TTY::Box.info("Format : #{self.format}\n" \
                               "File   : #{filename}\n" \
                               "Repo   : #{self.repo}\n",
                               width:   ui_width,
                               padding: 1)
            puts
            # —————————— actually get all issues ———————————————
            self.file.write send("render_as_#{format}", fetch_issues)
            # ————————————————————————————————————————————————————————

            puts
            puts TTY::Box.info("Success: written a total of #{record_count} records to #{filename}",
                               width: ui_width, padding: 1)
            puts
          ensure
            file.close if file.respond_to?(:close) && !file.closed?
          end

          def fetch_issues
            client.auto_paginate = true
            self.issues = client.issues(repo, **default_options).tap do |issue_list|
              self.record_count = issue_list.size
            end
          end

          def pages
            1
          end

          def default_options
            { state: 'open' }
          end

          CSV_MAP = {
            'Labels' => ->(issue) { issue.labels.join(',') },
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
                csv << [issue.id, issue.title.strip, issue.labels.to_a.map(&:name).join(','), issue.state]
              end
            end
          end

          private

          def file_name(repo)
            "#{user_info.login}.#{repo.gsub(%r{.*/}, '')}-issues.#{FORMATS[self.format.to_sym]}"
          end
        end
      end

      register 'issue', aliases: ['r'] do |prefix|
        prefix.register 'export', Issue::Export
      end
    end
  end
end
