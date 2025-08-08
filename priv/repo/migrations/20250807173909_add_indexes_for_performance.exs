defmodule UrlShortener.Repo.Migrations.AddIndexesForPerformance do
  use Ecto.Migration

  def change do
    # Note: links.slug unique index already exists from create_links migration
    # Note: redirect_metrics.link_id index already exists from create_redirect_metrics migration

    # Add index on redirect_metrics.inserted_at for time-based queries
    create index(:redirect_metrics, [:inserted_at])

    # Add composite index for common analytics queries
    create index(:redirect_metrics, [:link_id, :inserted_at])

    # Add index on redirect_metrics.ip_address for location analytics
    create index(:redirect_metrics, [:ip_address])

    # Add index on redirect_metrics.user_agent for browser analytics (partial index for performance)
    create index(:redirect_metrics, ["substring(user_agent, 1, 100)"],
             name: :redirect_metrics_user_agent_partial_index
           )
  end
end
