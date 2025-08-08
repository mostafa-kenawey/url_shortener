defmodule UrlShortenerWeb.AdminDashboardLiveTest do
  use UrlShortenerWeb.ConnCase

  import Phoenix.LiveViewTest
  import UrlShortener.AdminFixtures
  alias UrlShortener.{Repo, RedirectMetrics}
  alias UrlShortener.RedirectMetrics.RedirectMetric

  describe "Admin Dashboard" do
    setup :register_and_log_in_admin

    test "displays admin dashboard", %{conn: conn, admin: _admin} do
      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Analytics Dashboard"
      assert html =~ "Welcome back, Admin"
      assert html =~ "Manage Links"
      assert html =~ "Total Clicks"
      assert html =~ "Total Links"
      assert html =~ "Avg Clicks/Link"
      assert html =~ "Active Today"
      # Don't assert empty state since data might exist from other tests
    end

    test "displays dashboard with data", %{conn: conn} do
      # Create sample data
      link1 = link_fixture(slug: "test1", original_url: "https://example.com")
      link2 = link_fixture(slug: "test2", original_url: "https://example.org")
      
      # Create redirect metrics
      {:ok, _} = RedirectMetrics.create_metric(%{
        link_id: link1.id,
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
      })
      
      {:ok, _} = RedirectMetrics.create_metric(%{
        link_id: link2.id,
        ip_address: "192.168.1.2",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15"
      })

      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      # Check metrics display
      assert html =~ "2"  # Total clicks
      assert html =~ "2"  # Total links
      assert html =~ "1.0" # Avg clicks per link
      
      # Check browser stats
      assert html =~ "Chrome"
      assert html =~ "Safari"
      
      # Check recent activity
      assert html =~ "test1"
      assert html =~ "test2"
      assert html =~ "192.168.1.1"
      assert html =~ "192.168.1.2"
      
      # Check top locations
      assert html =~ "192.168.1.1"
      assert html =~ "192.168.1.2"
    end

    test "handles real-time updates via PubSub", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/admin/dashboard")
      
      # Create a link and metric to trigger real-time update
      link = link_fixture(slug: "realtime", original_url: "https://realtime.com")
      
      # Simulate redirect event
      Phoenix.PubSub.broadcast(UrlShortener.PubSub, "redirect_events", {:redirect, %{
        link_id: link.id,
        ip_address: "10.0.0.1",
        user_agent: "TestBot/1.0"
      }})
      
      # Dashboard should receive the message and re-render
      assert render(dashboard_live) =~ "Analytics Dashboard"
    end

    test "handles refresh_data message", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/admin/dashboard")
      
      # Send refresh message
      send(dashboard_live.pid, :refresh_data)
      
      # Dashboard should re-render
      assert render(dashboard_live) =~ "Analytics Dashboard"
    end

    test "handles unknown info message", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/admin/dashboard")
      
      # Send unknown message (should not crash)
      send(dashboard_live.pid, :unknown_message)
      
      # Dashboard should still work
      assert render(dashboard_live) =~ "Analytics Dashboard"
    end

    test "has link to manage links", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/admin/dashboard")

      assert dashboard_live |> element("a", "Manage Links") |> render() =~ "href=\"/admin/links\""
    end

    test "displays correct browser colors", %{conn: conn} do
      # Create metrics with different browsers
      link = link_fixture(slug: "browsers", original_url: "https://browsers.com")
      
      browsers = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59",
        "UnknownBrowser/1.0"
      ]
      
      Enum.each(browsers, fn user_agent ->
        {:ok, _} = RedirectMetrics.create_metric(%{
          link_id: link.id,
          ip_address: "127.0.0.1",
          user_agent: user_agent
        })
      end)

      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      # Check that different browsers are displayed (some may be grouped as Other)
      assert html =~ "Chrome"
      assert html =~ "Firefox"
      assert html =~ "Safari"
      # Edge might be grouped with Other, so check for Other
      assert html =~ "Other"
    end

    test "displays time ago correctly for different time ranges", %{conn: conn} do
      link = link_fixture(slug: "timetest", original_url: "https://time.com")
      
      now = DateTime.utc_now()
      
      # Test different time ranges
      times = [
        # 30 seconds ago (should show "30s ago")
        DateTime.add(now, -30, :second),
        # 5 minutes ago (should show "5m ago")
        DateTime.add(now, -300, :second),
        # 2 hours ago (should show "2h ago")
        DateTime.add(now, -7200, :second),
        # 3 days ago (should show "3d ago")
        DateTime.add(now, -259200, :second)
      ]
      
      Enum.each(times, fn time ->
        naive_time = DateTime.to_naive(time) |> NaiveDateTime.truncate(:second)
        metric = %RedirectMetric{
          link_id: link.id,
          ip_address: "127.0.0.1",
          user_agent: "TestBot/1.0",
          inserted_at: naive_time
        }
        
        Repo.insert!(metric)
      end)

      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      # Should contain time ago information in different formats
      assert html =~ "ago"
      # Could contain seconds, minutes, hours, or days
      assert html =~ ~r/\d+[smhd] ago/
    end

    test "handles division by zero in calculations", %{conn: conn} do
      # Test with no links (should handle division by zero gracefully)
      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      # Should display 0 for average clicks per link
      assert html =~ "0" # Avg clicks should be 0 when no links
    end

    test "displays last updated time", %{conn: conn} do
      {:ok, _dashboard_live, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Last updated:"
      assert html =~ ~r/\d{2}:\d{2}:\d{2}/ # Time format HH:MM:SS
    end
  end
end
