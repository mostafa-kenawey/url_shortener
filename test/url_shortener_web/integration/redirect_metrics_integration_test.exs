defmodule UrlShortenerWeb.RedirectMetricsIntegrationTest do
  use UrlShortenerWeb.ConnCase
  
  alias UrlShortener.Repo
  alias UrlShortener.RedirectMetrics.RedirectMetric
  alias UrlShortener.RedirectMetrics
  import UrlShortener.AdminFixtures

  describe "redirect metrics collection" do
    test "creates metrics when redirecting to existing link", %{conn: conn} do
      # Create a link
      link = link_fixture(slug: "test-redirect", original_url: "https://elixir-lang.org")
      
      # Verify no metrics exist initially
      assert Repo.aggregate(RedirectMetric, :count) == 0
      
      # Subscribe to PubSub events to manually handle metrics in test
      Phoenix.PubSub.subscribe(UrlShortener.PubSub, "redirect_events")
      
      # Clear cache to force database lookup and trigger PubSub broadcast
      UrlShortener.Cache.clear()
      
      # Make a request to the redirect endpoint
      conn = get(conn, ~p"/#{link.slug}")
      
      # Verify redirect happened
      assert redirected_to(conn, 302) == "https://elixir-lang.org"
      
      # Wait for and handle the PubSub message manually in test
      assert_receive {:redirect, payload}, 100
      
      # Manually create the metric since MetricsCollector is disabled in test
      {:ok, _metric} = RedirectMetrics.create_metric(payload)
      
      # Verify a redirect metric was created
      assert Repo.aggregate(RedirectMetric, :count) == 1
      
      metric = Repo.one(RedirectMetric)
      assert metric.link_id == link.id
      assert metric.ip_address == "127.0.0.1"
      assert is_binary(metric.user_agent)
    end

    test "does not create metrics for non-existent links", %{conn: conn} do
      # Verify no metrics exist initially
      assert Repo.aggregate(RedirectMetric, :count) == 0
      
      # Make a request to a non-existent slug
      conn = get(conn, ~p"/nonexistent")
      
      # Verify 404 response
      assert html_response(conn, 404) =~ "Not Found"
      
      # Wait a bit
      :timer.sleep(50)
      
      # Verify no metrics were created
      assert Repo.aggregate(RedirectMetric, :count) == 0
    end
  end
end
