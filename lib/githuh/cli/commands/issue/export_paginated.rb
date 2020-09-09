# frozen_string_literal: true

require_relative 'export'

module Githuh
  module CLI
    module Commands
      module Issue
        class ExportPaginated < Export
          def fetch_issues
            page = 0
            bar  = nil

            [].tap do |issue_list|
              loop do
                options = default_options.merge({
                                                  page:     page,
                                                  per_page: per_page,
                                                })

                puts "page: #{page}"
                issues_page = client.issues(repo, **options)

                break if issues_page.nil? || issues_page.empty?

                issue_list.concat(issues_page)

                bar("#{repo} Issues Export")&.advance
                page              += 1
                self.record_count += issues_page.size
              end

              bar&.finish; puts

              issue_list << issues
            end.flatten
          end
        end
      end
    end
  end
end
