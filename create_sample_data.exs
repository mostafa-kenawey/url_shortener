# Script to create sample analytics data for testing the dashboard
# Run with: mix run create_sample_data.exs

IO.puts("Creating sample data for analytics dashboard...")

# Create some sample links
links = [
  %{original_url: "https://elixir-lang.org", slug: "elixir"},
  %{original_url: "https://phoenixframework.org", slug: "phoenix"},
  %{original_url: "https://github.com/elixir-lang/elixir", slug: "elixir-github"},
  %{original_url: "https://hexdocs.pm", slug: "docs"},
  %{original_url: "https://elixirforum.com", slug: "forum"}
]

created_links =
  Enum.map(links, fn link_attrs ->
    case UrlShortener.Admin.create_link(link_attrs) do
      {:ok, link} ->
        IO.puts("Created link: #{link.slug} -> #{link.original_url}")
        link

      {:error, changeset} ->
        # Link might already exist, try to find it
        case UrlShortener.Links.get_link_by_slug(link_attrs.slug) do
          nil ->
            IO.puts("Failed to create link: #{inspect(changeset.errors)}")
            nil

          existing_link ->
            IO.puts("Link already exists: #{existing_link.slug}")
            existing_link
        end
    end
  end)
  |> Enum.filter(& &1)

IO.puts("Creating sample analytics data...")

# Sample user agents and IPs for realistic data
user_agents = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59"
]

ip_addresses = [
  "192.168.1.100",
  "192.168.1.101",
  "192.168.1.102",
  "10.0.0.1",
  "10.0.0.2",
  "172.16.0.1",
  "172.16.0.2",
  "203.0.113.1",
  "203.0.113.2",
  "198.51.100.1"
]

# Create metrics with varying popularity
Enum.each(created_links, fn link ->
  # Different popularity levels - some links more popular than others
  click_count =
    case link.slug do
      # Most popular
      "elixir" -> Enum.random(50..100)
      # Second most popular
      "phoenix" -> Enum.random(30..60)
      # Moderate
      "docs" -> Enum.random(20..40)
      # Less popular
      _ -> Enum.random(5..20)
    end

  IO.puts("Creating #{click_count} clicks for #{link.slug}")

  # Create clicks spread over the last few days
  Enum.each(1..click_count, fn _ ->
    # Random timestamp in the last 7 days
    days_ago = Enum.random(0..6)
    hours_ago = Enum.random(0..23)
    minutes_ago = Enum.random(0..59)

    click_time =
      DateTime.utc_now()
      |> DateTime.add(-days_ago, :day)
      |> DateTime.add(-hours_ago, :hour)
      |> DateTime.add(-minutes_ago, :minute)

    metric_attrs = %{
      link_id: link.id,
      ip_address: Enum.random(ip_addresses),
      user_agent: Enum.random(user_agents),
      inserted_at:
        NaiveDateTime.from_iso8601!(DateTime.to_iso8601(click_time) |> String.replace("Z", ""))
    }

    # Insert directly to control timestamp
    changeset =
      UrlShortener.RedirectMetrics.RedirectMetric.changeset(
        %UrlShortener.RedirectMetrics.RedirectMetric{},
        metric_attrs
      )

    case UrlShortener.Repo.insert(changeset) do
      {:ok, _} -> :ok
      {:error, reason} -> IO.puts("Error creating metric: #{inspect(reason)}")
    end
  end)
end)

# Get final statistics
total_links = length(created_links)
total_clicks = UrlShortener.RedirectMetrics.get_total_clicks()

IO.puts("Sample data creation completed!")
IO.puts("Created #{total_links} links with #{total_clicks} total clicks")
IO.puts("Visit http://localhost:4000/admin/dashboard to see the analytics!")
IO.puts("Make sure you're logged in as an admin user")
