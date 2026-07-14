defmodule SmartTicket.Infra do
  @moduledoc """
  Simulated infrastructure module for testing diagnostic tools.
  """

  def get_service_status(service) do
    case service do
      "web_frontend" ->
        %{
          health: "unhealthy",
          cpu_usage: "95%",
          memory_usage: "85%",
          uptime_seconds: 3600
        }

      "api_gateway" ->
        %{
          health: "healthy",
          cpu_usage: "45%",
          memory_usage: "60%",
          uptime_seconds: 86400
        }

      "database" ->
        %{
          health: "healthy",
          cpu_usage: "30%",
          memory_usage: "70%",
          uptime_seconds: 172800
        }

      "cache" ->
        %{
          health: "healthy",
          cpu_usage: "20%",
          memory_usage: "40%",
          uptime_seconds: 86400
        }

      _ ->
        %{
          health: "unknown",
          cpu_usage: "0%",
          memory_usage: "0%",
          uptime_seconds: 0
        }
    end
  end

  def restart_service(service) when service in ["web_frontend", "api_gateway", "database", "cache"] do
    :ok
  end

  def restart_service(_service) do
    {:error, "Unknown service"}
  end
end
