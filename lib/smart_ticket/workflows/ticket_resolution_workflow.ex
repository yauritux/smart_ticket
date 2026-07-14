defmodule SmartTicket.Workflows.TicketResolutionWorkflow do
  @moduledoc """
  Orchestrates the 2-agent workflow: Triage → Diagnostic
  """
  require Logger

  alias SmartTicket.Agents.{TriageAgent, DiagnosticAgent}

  def run(ticket) do
    {:ok, triage_result} = TriageAgent.run(ticket.text)
    
    Logger.info("Triage complete: priority=#{triage_result["priority"]}, sentiment=#{triage_result["sentiment"]}")

    resolution_result = 
      if triage_result["priority"] in ["high", "critical"] do
        {:ok, diagnostic_result} = DiagnosticAgent.run(triage_result["extracted_error_code"])
        
        Logger.info("Diagnostic complete: status=#{diagnostic_result.status}")
        
        diagnostic_result
      else
        %{status: "not_applicable", resolution: "Low priority ticket - no diagnostic needed"}
      end

    {:ok, %{
      ticket_id: ticket.id,
      triage: triage_result,
      resolution: resolution_result
    }}
  end
end