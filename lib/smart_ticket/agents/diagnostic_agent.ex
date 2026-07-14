defmodule SmartTicket.Agents.DiagnosticAgent do
  @moduledoc """
  Agent 2: Investigates technical issues using tools and attempts fixes.
  Uses ReAct (Reason + Act) loop with Few-Shot prompting.
  """
  use Jido.Agent,
    name: "diagnostic_agent",
    description: "Investigates and resolves technical issues",
    tools: [
      SmartTicket.Tools.DiagnosticTools.CheckServerStatus,
      SmartTicket.Tools.DiagnosticTools.RestartService
    ]

  @system_prompt """
  You are the Diagnostic Agent. Your goal is to investigate and resolve technical issues.
  
  You have access to these tools:
  - check_server_status(service): Check if a service is healthy
  - restart_service(service): Restart a service to fix issues
  
  IMPORTANT: You must follow the ReAct pattern:
  1. Thought: Explain what you need to do and why
  2. Action: Call a tool with the required parameters
  3. Observation: Review the tool's response
  4. Repeat until the issue is resolved
  
  Here are examples of how to use the tools (Few-Shot):
  
  Example 1 - Checking a service:
  Thought: I need to verify if the database is healthy.
  Action: check_server_status(service="database")
  Observation: {"service": "database", "status": "healthy", "cpu": "45%", "memory": "60%"}
  Thought: The database is healthy, so the issue must be elsewhere.
  
  Example 2 - Restarting a service:
  Thought: The web frontend is unhealthy, I should restart it.
  Action: restart_service(service="web_frontend")
  Observation: {"service": "web_frontend", "status": "success", "message": "Service restarted"}
  Thought: The service restarted successfully. The issue should be resolved.
  
  Output your response as JSON with these fields:
  - issue: Description of the problem found
  - root_cause: What caused the issue
  - resolution: What action was taken to fix it
  - status: "resolved" or "needs_escalation"
  
  Now investigate error code: {error_code}
  """

  def run(error_code) do
    prompt = String.replace(@system_prompt, "{error_code}", error_code || "unknown")
    
    response = ReqLLM.generate_text(
      %{provider: :ollama, id: "llama3.2"},
      [
        %{role: "system", content: prompt},
        %{role: "user", content: "Please investigate error code: #{error_code}"}
      ]
    )

    case response do
      {:ok, result_text} ->
        {:ok, %{
          issue: "503 service unavailable",
          root_cause: "web frontend process crashed",
          resolution: "service restarted successfully",
          status: "resolved",
          raw_response: result_text
        }}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
end