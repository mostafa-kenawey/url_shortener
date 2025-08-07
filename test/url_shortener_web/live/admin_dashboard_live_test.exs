defmodule UrlShortenerWeb.AdminDashboardLiveTest do
  use UrlShortenerWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Admin Dashboard" do
    setup :register_and_log_in_admin

    test "displays admin dashboard", %{conn: conn, admin: admin} do
      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Admin Dashboard"
      assert html =~ "Welcome, #{admin.name}!"
      assert html =~ "Manage Links"
    end

    test "has link to manage links", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/admin/dashboard")

      assert dashboard_live |> element("a", "Manage Links") |> render() =~ "href=\"/admin/links\""
    end
  end
end
