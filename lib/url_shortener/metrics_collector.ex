defmodule UrlShortener.MetricsCollector do
  use GenServer
  require Logger
  alias UrlShortener.RedirectMetrics

  @topic "redirect_events"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Logger.info(">>> Subscribing to topic: #{inspect(@topic)}")

    case Phoenix.PubSub.subscribe(UrlShortener.PubSub, @topic) do
      :ok ->
        {:ok, state}

      error ->
        Logger.error("Failed to subscribe to #{@topic}: #{inspect(error)}")
        {:stop, {:subscription_failed, error}}
    end
  end

  def handle_info({:redirect, payload}, state) do
    try do
      case RedirectMetrics.create_metric(payload) do
        {:ok, _metric} ->
          :ok

        {:error, changeset} ->
          Logger.error("Failed to create redirect metric: #{inspect(changeset.errors)}")
      end
    rescue
      exception ->
        Logger.error("Exception creating redirect metric: #{inspect(exception)}")
    end

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
