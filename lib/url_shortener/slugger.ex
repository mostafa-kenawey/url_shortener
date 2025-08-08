defmodule UrlShortener.Slugger do
  @moduledoc """
  Utility module for generating unique URL-safe slugs.

  Provides functions to create short, unique identifiers for shortened URLs
  using cryptographically secure random bytes.
  """

  def generate_unique_slug(length \\ 6) do
    slug =
      :crypto.strong_rand_bytes(length)
      |> Base.url_encode64(padding: false)
      |> binary_part(0, length)

    # Check uniqueness (simplified - better done async or DB safe insert)
    if UrlShortener.Links.get_link_by_slug(slug), do: generate_unique_slug(length), else: slug
  end
end
