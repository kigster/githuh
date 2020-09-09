# frozen_string_literal: true

require 'colored2'
require 'json'

class CoverageBadge
  attr_reader :badge_image, :output

  COVERAGE_RESULT = ::File.expand_path('../../coverage/.last_run.json', __dir__).freeze
  COVERAGE_IMAGE  = ::File.expand_path('../../docs/img/coverage.svg', __dir__).freeze
  COVERAGE_COLORS = {
    (90..100) => '#1BFF00',
    (67...90) => '#4BAF00',
    (60...67) => '#69A707',
    (55...60) => '#69BC07',
    (45...55) => '#BFB900',
    (25...45) => '#9D5100',
    (0...25) => '#CC0E00'
  }.freeze

  def initialize(output = STDERR)
    @output      = output
    @badge_image = COVERAGE_IMAGE
  end

  def generate!(percentage = nil)
    return unless File.exist?(COVERAGE_RESULT)

    percentage ||= read_from_file
    output.puts
    output.puts ' • Attempting to generate the Coverage Badge for '.green + sprintf('%.2f%%', percentage).bold.yellow + ' coverage...'.green
    File.open(badge_image, 'w') { |f| f.write(template('COVERAGE', sprintf('%.2f', percentage))) }
    output.puts ' • Coverage badge SVG was saved into: '.green + badge_image.bold.yellow + '.'.green
    output.puts
  rescue StandardError => e
    output.puts ' • CoverageBadge was unable to generate a badge:'.red.italic
    output.puts "\t" + e.message.bold.red
  end

  private

  def read_from_file
    ::JSON.parse(::File.read(COVERAGE_RESULT))['result']['covered_percent'].to_f
  end

  TEMPLATE = ERB.new(
    File.read(
      File.expand_path(
        './coverage_badge.svg.erb',
        __dir__
      )
    ).freeze
  ).freeze

  BadgeTuple = Struct.new(:title, :cov, :color)

  def template(title, percentage)
    badge_tuple = BadgeTuple.new(title, '%d%%' % percentage.to_i)
    badge_tuple.color = '#f00'

    COVERAGE_COLORS.each_pair do |range, coverage_color|
      if range.include?(percentage.to_i)
        badge_tuple.color = coverage_color
        break
      end
    end

    begin
      badge_tuple.instance_eval do
        return TEMPLATE.result(binding)
      end
    rescue StackError => e
      warn "ERROR: #{e.message.bold.red}"
      warn e.backtrace&.reverse&.join("\n")
      raise e
    end
  end
end
