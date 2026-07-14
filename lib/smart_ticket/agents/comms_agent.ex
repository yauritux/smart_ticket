defmodule SmartTicket.Agents.CommsAgent do
  @moduledoc """
  Agent 3: Drafts customer-facing communications.
  Uses CREATE framework with strict tone control.
  """
  use Jido.Agent,
    name: "comms_agent",
    description: "Drafts empathetic customer communications"

  @system_prompt """
  [CONTEXT] You are the Customer Communications Agent. You write emails to customers 
  after their technical issues have been resolved.

  [RESULT] Write a short, professional email confirming the issue is resolved.

  [EXPLAIN] The customer may be stressed or frustrated. We need to:
  - Acknowledge their situation empathetically
  - Confirm the issue is fixed
  - NOT mention internal tool names or technical jargon
  - NOT apologize excessively (we fixed it, so be confident)
  - Keep it concise (under 100 words)

  [AUDIENCE] A customer who just experienced a technical issue.

  [TONE] Empathetic, professional, reassuring, and confident.
  Match the emotion level to the customer's sentiment:
  - If sentiment is "highly_negative_anxious" → Extra empathetic and reassuring
  - If sentiment is "neutral" → Professional and straightforward

  [EDIT] Output ONLY the email body (subject + message). No JSON, no markdown.
  Include a polite sign-off. Keep under 100 words total.

  Email format:
  Subject: [Brief, clear subject line]
  
  [Email body]
  
  [Sign-off]
  """

  def run(context) do
    response = ReqLLM.generate_text(
      "anthropic:claude-sonnet-4-5-20250929",
      [
        %{role: "system", content: @system_prompt},
        %{role: "user", content: format_context(context)}
      ]
    )

    case response do
      {:ok, email_text} ->
        {:ok, parse_email(email_text, context)}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_context(context) do
    """
    Customer: #{context.customer_name} (#{context.customer_email})
    Original Issue: #{context.original_issue}
    Resolution: #{context.resolution}
    Customer Sentiment: #{context.sentiment}
    """
  end

  defp parse_email(email_text, context) do
    # Parse the email text into subject and body
    [subject_line | body_lines] = String.split(email_text, "\n", parts: 2)
    subject = String.replace(subject_line, "Subject:", "") |> String.trim()
    body = Enum.join(body_lines, "\n") |> String.trim()

    %{
      to: context.customer_email,
      subject: subject,
      body: body,
      customer_name: context.customer_name
    }
  end
end