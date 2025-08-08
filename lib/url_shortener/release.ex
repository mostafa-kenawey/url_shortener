defmodule UrlShortener.Release do
  @moduledoc """
  Handles all release-related tasks like database setup and migrations.
  This module is designed to be run from inside a Docker container.
  """
  require Logger
  @app :url_shortener

  @doc """
  The main entrypoint for release tasks.
  It ensures the database is created and migrated.
  """
  def migrate do
    # The application and its repos are not started yet in a release.
    # We must start them ourselves.
    start_services()

    # Wait for the database to be connectable.
    wait_for_db()

    # Run migrations to set up the schema.
    run_migrations()
  end

  defp start_services do
    Logger.info("Starting services for release task...")
    Application.load(@app)
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:postgrex)
    Application.ensure_all_started(:ecto)
    Application.ensure_all_started(:ecto_sql)

    for repo <- repos() do
      repo.start_link(name: repo)
    end

    Logger.info("Services started.")
  end

  defp wait_for_db(retries \\ 10)

  defp wait_for_db(0) do
    Logger.error("Could not connect to the database. Aborting.")
    System.halt(1)
  end

  defp wait_for_db(retries) do
    case repos() do
      [repo | _] ->
        # Use a simple query to check if the DB is ready
        case Ecto.Adapters.SQL.query(repo, "SELECT 1", []) do
          {:ok, _} ->
            Logger.info("Database is ready to accept connections.")
            :ok

          {:error, _reason} ->
            Logger.warning("Database not ready yet. Retrying in 3 seconds...")
            Process.sleep(3000)
            wait_for_db(retries - 1)
        end

      [] ->
        Logger.warning("No Ecto repositories found in config.")
    end
  end

  defp run_migrations do
    Logger.info("Running database migrations...")

    for repo <- repos() do
      # Create the database if it doesn't exist. This is idempotent.
      case repo.__adapter__().storage_up(repo.config()) do
        :ok ->
          Logger.info("Database for #{inspect(repo)} created.")

        {:error, :already_up} ->
          Logger.info("Database for #{inspect(repo)} already exists.")

        {:error, reason} ->
          Logger.error("Failed to create database: #{inspect(reason)}")
          System.halt(1)
      end

      # Run migrations
      migrated = Ecto.Migrator.run(repo, :up, all: true)
      Logger.info("Migrations for #{inspect(repo)} complete.")
      migrated
    end
  end

  defp repos, do: Application.get_env(@app, :ecto_repos, [])
end
