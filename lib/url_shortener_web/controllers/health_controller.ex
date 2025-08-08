defmodule UrlShortenerWeb.HealthController do
  @moduledoc """
  Health check endpoint for monitoring and load balancer health checks.

  Provides a simple health check that verifies:
  - Application is running and responding
  - Database connectivity is working

  Returns appropriate HTTP status codes:
  - 200 OK when all systems are healthy
  - 503 Service Unavailable when there are issues
  """
  use UrlShortenerWeb, :controller

  def check(conn, _params) do
    # Simple health check - you can add more sophisticated checks here
    # like database connectivity, cache status, etc.

    try do
      # Check database connectivity
      UrlShortener.Repo.query!("SELECT 1")

      conn
      |> put_status(200)
      |> json(%{status: "ok", timestamp: DateTime.utc_now()})
    rescue
      _ ->
        conn
        |> put_status(503)
        |> json(%{status: "error", message: "Service unavailable"})
    end
  end
end
