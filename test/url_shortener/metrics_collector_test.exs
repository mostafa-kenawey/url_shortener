defmodule UrlShortener.MetricsCollectorTest do
  use UrlShortener.DataCase

  alias UrlShortener.RedirectMetrics.RedirectMetric

  import Phoenix.PubSub

  @topic "redirect_events"

  describe "handle_info with :redirect event" do
    setup do
      {:ok, link} = UrlShortener.Admin.create_link(%{
        original_url: "https://example.com",
        slug: "genserver-test"
      })

      %{link: link}
    end

    test "stores the redirect event in the database", %{link: link} do
      payload = %{
        link_id: link.id,
        ip_address: "192.168.1.100",
        user_agent: "TestBot/2.0"
      }

      broadcast(UrlShortener.PubSub, @topic, {:redirect, payload})

      # Wait for async Task to complete
      :timer.sleep(100)

      metric = Repo.one(RedirectMetric)

      assert metric.link_id == link.id
      assert metric.ip_address == "192.168.1.100"
      assert metric.user_agent == "TestBot/2.0"
    end
  end
end
