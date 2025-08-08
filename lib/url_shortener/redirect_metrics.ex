defmodule UrlShortener.RedirectMetrics do
  @moduledoc """
  Context module for managing redirect metrics and analytics.

  Provides functions for creating, retrieving, and analyzing redirect metrics
  data with built-in caching for performance. Tracks clicks, browser usage,
  geographic data, and other analytics for shortened URLs.
  """

  import Ecto.Query
  alias UrlShortener.Repo
  alias UrlShortener.RedirectMetrics.RedirectMetric
  alias UrlShortener.Admin.Link
  alias UrlShortener.Cache

  def create_metric(attrs) do
    case %RedirectMetric{} |> RedirectMetric.changeset(attrs) |> Repo.insert() do
      {:ok, _metric} = result ->
        # Invalidate analytics caches when new data is created
        invalidate_analytics_cache()
        result

      error ->
        error
    end
  end

  def get_total_clicks do
    case Cache.get_analytics("total_clicks") do
      {:ok, count} ->
        count

      {:error, :not_found} ->
        count = Repo.aggregate(RedirectMetric, :count)
        Cache.put_analytics("total_clicks", count, :timer.minutes(5))
        count
    end
  end

  def get_clicks_by_link do
    case Cache.get_analytics("clicks_by_link") do
      {:ok, data} ->
        data

      {:error, :not_found} ->
        query =
          from m in RedirectMetric,
            join: l in Link,
            on: m.link_id == l.id,
            group_by: [l.id, l.slug, l.original_url],
            select: %{
              link_id: l.id,
              slug: l.slug,
              original_url: l.original_url,
              click_count: count(m.id),
              latest_click: max(m.inserted_at)
            },
            order_by: [desc: count(m.id)]

        data = Repo.all(query)
        Cache.put_analytics("clicks_by_link", data, :timer.minutes(10))
        data
    end
  end

  def get_browser_stats do
    case Cache.get_analytics("browser_stats") do
      {:ok, data} ->
        data

      {:error, :not_found} ->
        query =
          from m in RedirectMetric,
            select: %{
              browser: fragment("CASE 
              WHEN ? LIKE '%Chrome%' THEN 'Chrome'
              WHEN ? LIKE '%Firefox%' THEN 'Firefox' 
              WHEN ? LIKE '%Safari%' THEN 'Safari'
              WHEN ? LIKE '%Edge%' THEN 'Edge'
              ELSE 'Other'
              END", m.user_agent, m.user_agent, m.user_agent, m.user_agent),
              count: count(m.id)
            },
            group_by: fragment("CASE 
            WHEN ? LIKE '%Chrome%' THEN 'Chrome'
            WHEN ? LIKE '%Firefox%' THEN 'Firefox'
            WHEN ? LIKE '%Safari%' THEN 'Safari' 
            WHEN ? LIKE '%Edge%' THEN 'Edge'
            ELSE 'Other'
            END", m.user_agent, m.user_agent, m.user_agent, m.user_agent),
            order_by: [desc: count(m.id)]

        data = Repo.all(query)
        Cache.put_analytics("browser_stats", data, :timer.minutes(15))
        data
    end
  end

  def get_recent_clicks(limit \\ 10) do
    cache_key = "recent_clicks_#{limit}"

    case Cache.get_analytics(cache_key) do
      {:ok, data} ->
        data

      {:error, :not_found} ->
        query =
          from m in RedirectMetric,
            join: l in Link,
            on: m.link_id == l.id,
            select: %{
              slug: l.slug,
              original_url: l.original_url,
              ip_address: m.ip_address,
              user_agent: m.user_agent,
              inserted_at: m.inserted_at
            },
            order_by: [desc: m.inserted_at],
            limit: ^limit

        data = Repo.all(query)
        # Shorter cache for recent data
        Cache.put_analytics(cache_key, data, :timer.minutes(2))
        data
    end
  end

  def get_clicks_over_time(days \\ 7) do
    cache_key = "clicks_over_time_#{days}"

    case Cache.get_analytics(cache_key) do
      {:ok, data} ->
        data

      {:error, :not_found} ->
        start_date = DateTime.utc_now() |> DateTime.add(-days, :day) |> DateTime.to_date()

        query =
          from m in RedirectMetric,
            where: fragment("DATE(?)", m.inserted_at) >= ^start_date,
            group_by: fragment("DATE(?)", m.inserted_at),
            select: %{
              date: fragment("DATE(?)", m.inserted_at),
              count: count(m.id)
            },
            order_by: fragment("DATE(?)", m.inserted_at)

        data = Repo.all(query)
        # Longer cache for historical data
        Cache.put_analytics(cache_key, data, :timer.hours(1))
        data
    end
  end

  def get_top_locations(limit \\ 10) do
    cache_key = "top_locations_#{limit}"

    case Cache.get_analytics(cache_key) do
      {:ok, data} ->
        data

      {:error, :not_found} ->
        query =
          from m in RedirectMetric,
            select: %{
              ip_address: m.ip_address,
              count: count(m.id)
            },
            group_by: m.ip_address,
            order_by: [desc: count(m.id)],
            limit: ^limit

        data = Repo.all(query)
        Cache.put_analytics(cache_key, data, :timer.minutes(20))
        data
    end
  end

  # Helper function to invalidate analytics caches when new metrics are created
  defp invalidate_analytics_cache do
    Cache.clear_pattern("analytics:")
  end
end
