defmodule UrlShortenerWeb.HealthController do
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
