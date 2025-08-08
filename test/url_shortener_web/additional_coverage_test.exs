defmodule UrlShortenerWeb.AdditionalCoverageTest do
  use UrlShortenerWeb.ConnCase

  import Phoenix.LiveViewTest
  import UrlShortener.AdminFixtures

  describe "Additional coverage tests" do
    setup :register_and_log_in_admin

    test "covers router branch for home page", %{conn: conn} do
      # Test the home page route
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "URL Shortener"
    end

    test "covers page controller", %{conn: conn} do
      # Test page controller home action
      conn = get(conn, "/")
      assert conn.status == 200
    end

    test "test admin link live delete confirmation", %{conn: conn} do
      # Create a link to delete
      link = link_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/admin/links")

      # Test the delete action with confirmation
      assert index_live |> element("#links-#{link.id} a", "Delete") |> render_click()

      # The link should be removed from the list
      refute has_element?(index_live, "#links-#{link.id}")
    end
  end
end
