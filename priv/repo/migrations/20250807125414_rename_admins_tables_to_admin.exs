defmodule UrlShortener.Repo.Migrations.RenameAdminsTablestoAdmin do
  use Ecto.Migration

  def change do
    # Drop indexes on the old table before renaming
    drop index(:admins_tokens, [:admin_id])
    drop unique_index(:admins_tokens, [:context, :token])
    
    # Rename the tables from admins/admins_tokens to admin/admin_tokens
    rename table(:admins), to: table(:admin)
    rename table(:admins_tokens), to: table(:admin_tokens)
    
    # Recreate indexes on the new table
    create index(:admin_tokens, [:admin_id])
    create unique_index(:admin_tokens, [:context, :token])
  end
end
