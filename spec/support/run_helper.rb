# frozen_string_literal: true

require 'colored2'

module RunHelper
  def complete_spec_run?
    total_spec_files_count == current_spec_file_count
  end

  def total_spec_files_count
    `find spec -type f -name '*_spec.rb' | wc -l`.chomp.to_i
  end

  def current_spec_file_count
    RSpec.configuration.files_to_run.size
  end

  def needs_new_badge?
    complete_spec_run? && ENV['CI'].nil?
  end

  def update_coverage_badge!
    generated_badge = 'coverage/coverage.svg'
    committed_badge = 'docs/img/coverage.svg'

    if needs_new_badge? && File.exist?(generated_badge) &&
       (!File.exist?(committed_badge) || !FileUtils.compare_file(committed_badge, generated_badge))

      puts 'Updating the coverage SVG file '.bold.green +
           committed_badge.bold.blue +
           ', so you will need to commit this change.'.bold.green

      FileUtils.mkdir_p(File.dirname(committed_badge), verbose: true)

      FileUtils.mv(generated_badge, File.dirname(committed_badge), force: true, verbose: true)

      puts git_add(committed_badge)
    end
  end

  def git_add(path)
    `git add #{path}`
  rescue StandardError
    nil
  end

  extend(self)
end
