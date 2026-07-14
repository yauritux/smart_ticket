import Config

config :jido_ai, model_aliases: %{
  fast_local: %{provider: :ollama, id: "llama3.2"}
}

config :req_llm, :ollama,
  base_url: System.get_env("OLLAMA_BASE_URL", "http://localhost:11434/v1")

