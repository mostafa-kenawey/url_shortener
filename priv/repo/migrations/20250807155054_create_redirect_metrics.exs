defmodule UrlShortener.Repo.Migrations.CreateRedirectMetrics do
  use Ecto.Migration

  def change do
    create table(:redirect_metrics) do
      add :link_id, references(:links, on_delete: :delete_all, type: :binary_id), null: false
      add :ip_address, :string
      add :user_agent, :text
      timestamps(updated_at: false)
    end

    create index(:redirect_metrics, [:link_id])
  end
end
