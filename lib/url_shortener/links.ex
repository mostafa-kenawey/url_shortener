defmodule UrlShortener.Links do
  @moduledoc """
  The Links context for link management.
  """

  import Ecto.Query, warn: false
  alias UrlShortener.Repo
  alias UrlShortener.Admin.Link

  @doc """
  Gets a link by slug.

  Returns the link if found, nil otherwise.

  ## Examples

      iex> get_link_by_slug("abc123")
      %Link{}

      iex> get_link_by_slug("nonexistent")
      nil

  """
  def get_link_by_slug(slug) do
    Repo.get_by(Link, slug: slug)
  end
end
