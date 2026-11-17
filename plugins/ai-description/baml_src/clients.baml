// LLM requests go through LiteLLM proxy which handles:
// - API key management (keys live in litellm/.env, not here)
// - PII filtering via Presidio guardrails
// - Observability via Langfuse
client<llm> LiteLlmProvider {
  provider openai
  options {
    model "gpt-5.4-nano"
    api_key env.LITELLM_API_KEY
    base_url "http://localhost:4000/v1"
  }
}

client<llm> LlmProvider {
  provider fallback
  options {
    strategy [LiteLlmProvider]
  }
}
