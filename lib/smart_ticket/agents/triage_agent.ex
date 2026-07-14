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
  - extracted_error_code: CRITICAL - Extract any HTTP error code (400, 401, 403, 404, 500, 502, 503, 504, etc.) or error number mentioned in the ticket. Return as a STRING (e.g., "503", "500"). If no error code found, return null.
  - key_issue: Brief summary of the main problem (max 20 words)

  [EXPLAIN] We need to route high-priority, high-emotion tickets immediately to
  the Diagnostic Agent. IMPORTANT: You MUST extract error codes accurately. Look for:
  - HTTP status codes (500, 503, 404, etc.)
  - Error numbers or codes in the text
  - Phrases like "error 503", "503 error", "showing a 503"
  If you miss the error code, the Diagnostic Agent won't know where to look.

  [AUDIENCE] This JSON will be parsed automatically by our Jido workflow engine.
  It must be valid JSON with no markdown formatting.

  [TONE] Analytical, objective, and precise.

  [EDIT] Output ONLY valid JSON. Do not include ```json markers or any other text.
  The "reasoning" field must come first and contain your step-by-step analysis.

  Example 1 - With error code:
  Input: "My dashboard is showing a 503 error and won't load!"
  {
    "reasoning": "Step 1: Customer mentions 503 error code explicitly. Step 2: Dashboard not loading indicates critical service issue. Step 3: Urgent tone suggests high anxiety.",
    "sentiment": "highly_negative_anxious",
    "priority": "critical",
    "extracted_error_code": "503",
    "key_issue": "Dashboard showing 503 error and not loading"
  }

  Example 2 - No error code:
  Input: "How do I export my data to CSV?"
  {
    "reasoning": "Step 1: Simple how-to question. Step 2: No urgency indicated. Step 3: Neutral tone.",
    "sentiment": "neutral",
    "priority": "low",
    "extracted_error_code": null,
    "key_issue": "Question about CSV export functionality"
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
