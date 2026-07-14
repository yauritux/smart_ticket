defmodule SmartTicket.Tools.DiagnosticTools do
  @moduledoc """
  Tools available to the Diagnostic Agent for investigating and fixing issues.
  """

  defmodule CheckServerStatus do
    use Jido.Action,
      name: "check_server_status",
      description: "Check the health status of a specific service",
      schema: %{
        "type" => "object",
        "properties" => %{
          "service" => %{
            "type" => "string",
            "enum" => ["web_frontend", "api_gateway", "database", "cache"],
            "description" => "The service to check"
          }
        },
        "required" => ["service"]
      }

    def run(%{service: service}, _state) do
      status = SmartTicket.Infra.get_service_status(service)
      
      {:ok, %{
        service: service,
        status: status.health,
        cpu: status.cpu_usage,
        memory: status.memory_usage,
        uptime: status.uptime_seconds
      }}
    end
  end

  defmodule RestartService do
    use Jido.Action,
      name: "restart_service",
      description: "Restart a specific service to resolve issues",
      schema: %{
        "type" => "object",
        "properties" => %{
          "service" => %{
            "type" => "string",
            "enum" => ["web_frontend", "api_gateway", "database", "cache"],
            "description" => "The service to restart"
          }
        },
        "required" => ["service"]
      }

    def run(%{service: service}, _state) do
      case SmartTicket.Infra.restart_service(service) do
        :ok ->
          {:ok, %{
            service: service,
            status: "success",
            message: "Service restarted successfully",
            timestamp: DateTime.utc_now()
          }}
        
        {:error, reason} ->
          {:error, %{
            service: service,
            status: "failed",
            error: reason
          }}
      end
    end
  end
end