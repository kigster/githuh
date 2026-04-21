# frozen_string_literal: true

require_relative 'base'

module Githuh
  module LLM
    class OpenAI < Base
      ENDPOINT = URI('https://api.openai.com/v1/chat/completions').freeze
      MODEL = 'gpt-4o-mini'
      MAX_TOKENS = 800
      BAR_COLOR = :green

      def summarize(readme)
        headers = { 'Authorization' => "Bearer #{api_key}" }
        body = {
          model:      MODEL,
          max_tokens: MAX_TOKENS,
          messages:   [{ role: 'user', content: prompt_for(readme) }]
        }

        payload = parse!(post_json(ENDPOINT, headers, body))
        payload.dig('choices', 0, 'message', 'content').to_s.strip
      end
    end
  end
end
