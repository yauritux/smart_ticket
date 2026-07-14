defmodule SmartTicket.Agents.TriageAgent do
  @moduledoc """
  Agent 1: Analyzes incoming support tickets and determines priority.
  Uses CREATE framework for structured prompting and Chain-of-Thought for reasoning.
  """
  use Jido.Agent,
    name: "triage_agent",
    description: "Analyzes customer support tickets and determines priority"

  @system_prompt """
  [CONTEXT] You are the first-line Triage Agent for a SaaS platform. 
  You receive raw customer support tickets and must quickly assess their urgency.

  [RESULT] You must output a strict JSON object containing:
  - reasoning: Your step-by-step analysis (required, must be first)
  - sentiment: One of ["positive", "neutral", "negative", "highly_negative_anxious"]
  - priority: One of ["low", "medium", "high", "critical"]
  - extracted_error_code: The error code mentioned (or null if none)
  - key_issue: Brief summary of the main problem (max 20 words)

  [EXPLAIN] We need to route high-priority, high-emotion tickets immediately to 
  the Diagnostic Agent. If you miss the error code, the Diagnostic Agent won't 
  know where to look. Your reasoning must come FIRST to ensure accurate analysis.

  [AUDIENCE] This JSON will be parsed automatically by our Jido workflow engine.
  It must be valid JSON with no markdown formatting.

  [TONE] Analytical, objective, and precise.

  [EDIT] Output ONLY valid JSON. Do not include ```json markers or any other text.
  The "reasoning" field must come first and contain your step-by-step analysis.

  Example output format:
  {
    "reasoning": "Step 1: Customer mentions X, which indicates Y. Step 2: The error code Z suggests...",
    "sentiment": "negative",
    "priority": "high",
    "extracted_error_code": "500",
    "key_issue": "Dashboard loading slowly with server error"
  }
  """

  def run(ticket_text) do
    response = ReqLLM.generate_object(
      %{provider: :ollama, id: "llama3.2"},
      [
        %{role: "system", content: @system_prompt},
        %{role: "user", content: ticket_text}
      ],
      json_schema()
    )

    case response do
      {:ok, %{object: parsed_json}} ->
        {:ok, parsed_json}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp json_schema do
    %{
      type: :object,
      properties: %{
        reasoning: %{type: :string},
        sentiment: %{
          type: :string,
          enum: ["positive", "neutral", "negative", "highly_negative_anxious"]
        },
        priority: %{
          type: :string,
          enum: ["low", "medium", "high", "critical"]
        },
        extracted_error_code: %{type: [:string, :null]},
        key_issue: %{type: :string}
      },
      required: ["reasoning", "sentiment", "priority", "key_issue"]
    }
  end
end