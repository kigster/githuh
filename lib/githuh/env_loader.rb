# frozen_string_literal: true

module Githuh
  module EnvLoader
    # Load a simple KEY=VALUE .env file from the current working directory
    # and/or HOME, without clobbering already-set ENV entries.
    def self.load!
      [File.join(Dir.pwd, '.env'), File.join(Dir.home, '.env')].uniq.each do |path|
        next unless File.file?(path) && File.readable?(path)

        File.foreach(path) do |raw|
          line = raw.strip
          next if line.empty? || line.start_with?('#')

          key, value = line.split('=', 2)
          next if key.nil? || value.nil?

          key = key.strip
          value = strip_quotes(value.strip)
          ENV[key] ||= value
        end
      end
    end

    def self.strip_quotes(value)
      if (value.start_with?('"') && value.end_with?('"')) ||
         (value.start_with?("'") && value.end_with?("'"))
        value[1..-2]
      else
        value
      end
    end
  end
end
