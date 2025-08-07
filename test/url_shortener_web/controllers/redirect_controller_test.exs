defmodule UrlShortenerWeb.RedirectControllerTest do
  use UrlShortenerWeb.ConnCase

  import UrlShortener.LinksFixtures

  describe "GET /:slug" do
    test "redirects to original URL when slug exists", %{conn: conn} do
      link = link_fixture(slug: "abc123", original_url: "https://elixir-lang.org")

      conn = get(conn, ~p"/#{link.slug}")
      assert redirected_to(conn, 302) == "https://elixir-lang.org"
    end

    test "renders 404 when slug does not exist", %{conn: conn} do
      conn = get(conn, ~p"/notfound")
      assert html_response(conn, 404) =~ "Not Found"
    end
  end
end
