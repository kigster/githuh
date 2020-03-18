# frozen_string_literal: true

require 'colored2'
require 'json'

class CoverageBadge
  attr_reader :badge_image, :output

  COVERAGE_RESULT = ::File.expand_path('../../coverage/.last_run.json', __dir__).freeze
  COVERAGE_IMAGE  = ::File.expand_path('../../docs/img/coverage.svg', __dir__).freeze
  COVERAGE_COLORS = {
    (85..100) => '#1BFF00',
    (65...85) => '#84E707',
    (55...65) => '#69BC07',
    (45...55) => '#BFB900',
    (25...45) => '#9D5100',
    (0...25) => '#CC0E00'
  }.freeze

  def initialize(output = STDERR)
    @output      = output
    @badge_image = COVERAGE_IMAGE
  end

  def generate!(percentage = read_from_file)
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

  def template(title, percentage)
    color = '#f00'

    COVERAGE_COLORS.each_pair do |range, coverage_color|
      if range.include?(percentage.to_i)
        color = coverage_color
        break
      end
    end

    cov = sprintf('%.1f', percentage)

    file_content = <<~SVGTEMPLATE
      <?xml version="1.0"?>
      <svg xmlns="http://www.w3.org/2000/svg" width="130" height="20">
        <linearGradient id="a" x2="0" y2="100%">
          <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
          <stop offset="1" stop-opacity=".1"/>
        </linearGradient>
        <rect rx="3" width="130" height="20" fill="#555"/>
        <rect rx="3" x="80" width="50" height="20" fill="#{color}"/>
        <rect rx="3" width="130" height="20" fill="url(#a)"/>
        <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="10">
          <text x="34.5" y="15" fill="#010101" fill-opacity=".3">#{title}</text>
          <text x="35.5" y="14">#{title}</text>
          <text x="105.5" y="15" fill="#010101" fill-opacity=".3">#{cov}%</text>
          <text x="106.5" y="14">#{cov}%</text>
        </g>
      </svg>
    SVGTEMPLATE
    file_content
  end
end
