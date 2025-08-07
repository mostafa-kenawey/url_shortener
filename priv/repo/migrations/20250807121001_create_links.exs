defmodule UrlShortener.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :original_url, :string
      add :slug, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:links, [:slug])
  end
end
