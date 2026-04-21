# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Githuh
  module LLM
    class Base
      # Hard cap to keep prompts cheap and within model context.
      README_CHAR_LIMIT = 12_000
      REQUEST_TIMEOUT = 30

      PROMPT = <<~PROMPT
        You are summarizing a GitHub repository for a public directory page.
        Below is the README. Write a user-friendly description of 5–6 sentences.
        Focus on: what the project *is*, what problem it *solves*, who would
        use it, and any notable technical approach or feature. Keep it flowing
        prose — no bullet points, no headings, no quotes, no markdown syntax.
        Do NOT include installation instructions, badges, license mentions,
        or author credits. Return ONLY the description prose — no preamble.

        README:
        ---
        %<readme>s
        ---
      PROMPT

      attr_reader :api_key, :name

      def initialize(api_key:)
        @api_key = api_key
        @name = self.class.name.split('::').last.downcase
      end

      # @param readme [String] raw README markdown
      # @return [String] a 2-4 sentence description
      def summarize(readme)
        raise NotImplementedError
      end

      protected

      def prompt_for(readme)
        format(PROMPT, readme: readme.to_s[0, README_CHAR_LIMIT])
      end

      def post_json(uri, headers, body)
        req = Net::HTTP::Post.new(uri)
        headers.each { |k, v| req[k] = v }
        req['Content-Type'] = 'application/json'
        req.body = JSON.dump(body)

        Net::HTTP.start(uri.hostname, uri.port,
                        use_ssl:      uri.scheme == 'https',
                        read_timeout: REQUEST_TIMEOUT,
                        open_timeout: REQUEST_TIMEOUT) do |http|
          http.request(req)
        end
      end

      def parse!(response)
        raise Error, "#{name} API #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end
    end
  end
end
