defmodule UrlShortener.Repo.Migrations.RenameAdminToAccounts do
  use Ecto.Migration

  def change do
    rename table(:admin), to: table(:accounts)
  end
end
