defmodule UrlShortener.Repo do
  @moduledoc """
  Database repository for UrlShortener application.

  This module configures the Ecto repository with PostgreSQL adapter and
  custom connection pool settings optimized for performance:
  - Increased pool size for better concurrency (15 connections)
  - Configured queue timeouts and intervals for optimal request handling
  - Database connection and query management
  """
  use Ecto.Repo,
    otp_app: :url_shortener,
    adapter: Ecto.Adapters.Postgres

  # Custom configuration for connection pooling and performance
  def init(_type, config) do
    # Configure connection pool settings
    config =
      config
      # Increase pool size for better concurrency
      |> Keyword.put(:pool_size, 15)
      # Queue timeout in ms
      |> Keyword.put(:queue_target, 5_000)
      # Queue check interval in ms
      |> Keyword.put(:queue_interval, 1_000)

    {:ok, config}
  end
end
