defmodule UrlShortener.Admin.Link do
  @moduledoc """
  Link schema for managing shortened URL links in the admin interface.

  This module defines the link data structure and validation rules for creating
  and managing shortened URLs. Each link consists of:
  - An original URL that users want to shorten
  - A unique slug that serves as the short identifier
  - Timestamps for creation and updates

  The module automatically generates unique slugs when none is provided and validates
  that URLs are properly formatted before saving.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "links" do
    field :original_url, :string
    field :slug, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:original_url, :slug])
    |> validate_required([:original_url])
    |> validate_format(:original_url, ~r/^https?:\/\/[^\s]+$/, message: "must be a valid URL")
    |> unique_constraint(:slug)
    |> put_slug()
  end

  defp put_slug(changeset) do
    case get_field(changeset, :slug) do
      nil ->
        slug = UrlShortener.Slugger.generate_unique_slug()
        put_change(changeset, :slug, slug)

      _ ->
        changeset
    end
  end
end
