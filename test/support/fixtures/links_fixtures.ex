defmodule UrlShortener.LinksFixtures do
  @moduledoc """
  This module defines test fixtures for links.
  """

  def link_fixture(attrs \\ %{}) do
    {:ok, link} =
      attrs
      |> Enum.into(%{
        original_url: "https://example.com",
        slug: "abc123"
      })
      |> UrlShortener.Admin.create_link()

    link
  end
end
