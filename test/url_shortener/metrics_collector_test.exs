defmodule UrlShortener.MetricsCollectorTest do
  use UrlShortener.DataCase

  alias UrlShortener.RedirectMetrics.RedirectMetric
  alias UrlShortener.MetricsCollector
  alias UrlShortener.RedirectMetrics

  import Phoenix.PubSub
  import ExUnit.CaptureLog

  @topic "redirect_events"

  describe "MetricsCollector" do
    setup do
      {:ok, link} = UrlShortener.Admin.create_link(%{
        original_url: "https://example.com",
        slug: "genserver-test"
      })

      # Start the MetricsCollector for this test (since it's disabled in test env)
      {:ok, collector_pid} = start_supervised({MetricsCollector, []})

      %{link: link, collector_pid: collector_pid}
    end

    test "stores the redirect event in the database", %{link: link} do
      payload = %{
        link_id: link.id,
        ip_address: "192.168.1.100",
        user_agent: "TestBot/2.0"
      }

      broadcast(UrlShortener.PubSub, @topic, {:redirect, payload})

      # Wait for async processing to complete
      :timer.sleep(100)

      metric = Repo.one(RedirectMetric)

      assert metric.link_id == link.id
      assert metric.ip_address == "192.168.1.100"
      assert metric.user_agent == "TestBot/2.0"
    end

    test "handles invalid link_id gracefully", %{collector_pid: _collector_pid} do
      log = capture_log(fn ->
        payload = %{
          link_id: "invalid-uuid",
          ip_address: "192.168.1.100",
          user_agent: "TestBot/2.0"
        }

        broadcast(UrlShortener.PubSub, @topic, {:redirect, payload})

        # Wait for processing
        :timer.sleep(100)
      end)

      # Should log exception but not crash
      assert log =~ "Exception creating redirect metric"
      
      # No metrics should be created
      assert Repo.aggregate(RedirectMetric, :count) == 0
    end

    test "handles exceptions during metric creation", %{link: link, collector_pid: _collector_pid} do
      log = capture_log(fn ->
        # Test with invalid data that would cause an exception
        payload = %{
          link_id: link.id,
          ip_address: String.duplicate("x", 300), # Too long for database
          user_agent: "TestBot/2.0"
        }

        broadcast(UrlShortener.PubSub, @topic, {:redirect, payload})

        # Wait for processing
        :timer.sleep(100)
      end)

      # Should log exception but not crash
      assert log =~ "Exception creating redirect metric"
    end

    test "handles unknown messages", %{collector_pid: collector_pid} do
      # Send unknown message
      send(collector_pid, :unknown_message)
      send(collector_pid, {:unknown, "data"})
      
      # GenServer should still be alive
      assert Process.alive?(collector_pid)
    end


    test "handles metric creation directly", %{link: link} do
      payload = %{
        link_id: link.id,
        ip_address: "192.168.1.100",
        user_agent: "TestBot/2.0"
      }

      # Test direct metric creation without PubSub
      {:ok, metric} = RedirectMetrics.create_metric(payload)

      assert metric.link_id == link.id
      assert metric.ip_address == "192.168.1.100"
      assert metric.user_agent == "TestBot/2.0"
    end
  end
end
