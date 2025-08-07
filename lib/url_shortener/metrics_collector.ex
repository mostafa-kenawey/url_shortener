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
    Phoenix.PubSub.subscribe(UrlShortener.PubSub, @topic)
    {:ok, state}
  end

  def handle_info({:redirect, payload}, state) do
    Logger.info(">>> Received redirect event: #{inspect(payload)}")
    
    try do
      case RedirectMetrics.create_metric(payload) do
        {:ok, _metric} -> 
          Logger.info(">>> Successfully created redirect metric")
        {:error, changeset} -> 
          Logger.error(">>> Failed to create redirect metric: #{inspect(changeset.errors)}")
      end
    rescue
      exception -> 
        Logger.error(">>> Exception creating redirect metric: #{inspect(exception)}")
        # Don't crash the GenServer, just log the error
    end
    
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug(">>> Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
