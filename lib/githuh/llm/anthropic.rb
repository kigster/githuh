# frozen_string_literal: true

require_relative 'base'

module Githuh
  module LLM
    class Anthropic < Base
      ENDPOINT = URI('https://api.anthropic.com/v1/messages').freeze
      MODEL = 'claude-haiku-4-5-20251001'
      MAX_TOKENS = 800
      BAR_COLOR = :yellow

      def summarize(readme)
        headers = {
          'x-api-key' => api_key,
          'anthropic-version' => '2023-06-01'
        }
        body = {
          model:      MODEL,
          max_tokens: MAX_TOKENS,
          messages:   [{ role: 'user', content: prompt_for(readme) }]
        }

        payload = parse!(post_json(ENDPOINT, headers, body))
        payload.dig('content', 0, 'text').to_s.strip
      end
    end
  end
end
