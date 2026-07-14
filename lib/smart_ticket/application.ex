defmodule SmartTicketingAgent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc """
  OTP Application with supervision trees for fault tolerance.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor,
       name: SmartTicket.TriageAgentSupervisor,
       strategy: :one_for_one,
       max_restarts: 5,
       max_seconds: 60},

      {DynamicSupervisor,
       name: SmartTicket.DiagnosticAgentSupervisor,
       strategy: :one_for_one,
       max_restarts: 10,
       max_seconds: 60},

      {DynamicSupervisor,
       name: SmartTicket.WorkflowSupervisor,
       strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: SmartTicket.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
