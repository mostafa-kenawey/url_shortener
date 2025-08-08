defmodule UrlShortener.Repo do
  use Ecto.Repo,
    otp_app: :url_shortener,
    adapter: Ecto.Adapters.Postgres
  
  # Custom configuration for connection pooling and performance
  def init(_type, config) do
    # Configure connection pool settings
    config = 
      config
      |> Keyword.put(:pool_size, 15)  # Increase pool size for better concurrency
      |> Keyword.put(:queue_target, 5_000)  # Queue timeout in ms
      |> Keyword.put(:queue_interval, 1_000)  # Queue check interval in ms
    
    {:ok, config}
  end
end
