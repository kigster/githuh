# frozen_string_literal: true

module Githuh
  module LLM
    class Error < StandardError; end

    # Returns an adapter instance based on available env vars.
    # Priority: ANTHROPIC_API_KEY > OPENAI_API_KEY.
    # Returns nil if no key is set (caller decides how to handle).
    def self.build
      if (key = env('ANTHROPIC_API_KEY'))
        Anthropic.new(api_key: key)
      elsif (key = env('OPENAI_API_KEY'))
        OpenAI.new(api_key: key)
      end
    end

    def self.available?
      !build.nil?
    end

    def self.env(name)
      value = ENV.fetch(name, nil)
      value && !value.strip.empty? ? value.strip : nil
    end
  end
end

require_relative 'llm/base'
require_relative 'llm/anthropic'
require_relative 'llm/openai'
