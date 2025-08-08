defmodule UrlShortener.Cache do
  @moduledoc """
  Cache module for URL shortener using Cachex.

  Provides caching for:
  - URL slug to original URL mapping
  - Analytics data
  - Session data
  - Rate limiting
  """

  @cache_name :url_shortener_cache
  # 24 hours default TTL
  @default_ttl :timer.hours(24)

  # Cache keys
  @slug_prefix "slug:"
  @analytics_prefix "analytics:"
  @session_prefix "session:"
  @rate_limit_prefix "rate:"

  def start_link(opts \\ []) do
    Cachex.start_link(@cache_name, opts)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # Slug caching functions

  @doc """
  Cache a slug to original URL mapping.
  """
  def put_slug(slug, original_url, ttl \\ @default_ttl) do
    key = @slug_prefix <> slug
    Cachex.put(@cache_name, key, original_url, ttl: ttl)
  end

  @doc """
  Get original URL by slug from cache.
  """
  def get_slug(slug) do
    key = @slug_prefix <> slug

    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, original_url} -> {:ok, original_url}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Remove a slug from cache.
  """
  def delete_slug(slug) do
    key = @slug_prefix <> slug
    Cachex.del(@cache_name, key)
  end

  # Analytics caching functions

  @doc """
  Cache analytics data.
  """
  def put_analytics(key, data, ttl \\ :timer.minutes(15)) do
    cache_key = @analytics_prefix <> key
    Cachex.put(@cache_name, cache_key, data, ttl: ttl)
  end

  @doc """
  Get analytics data from cache.
  """
  def get_analytics(key) do
    cache_key = @analytics_prefix <> key

    case Cachex.get(@cache_name, cache_key) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, data} -> {:ok, data}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Remove analytics data from cache.
  """
  def delete_analytics(key) do
    cache_key = @analytics_prefix <> key
    Cachex.del(@cache_name, cache_key)
  end

  # Session caching functions

  @doc """
  Cache session data.
  """
  def put_session(session_id, data, ttl \\ :timer.hours(8)) do
    key = @session_prefix <> session_id
    Cachex.put(@cache_name, key, data, ttl: ttl)
  end

  @doc """
  Get session data from cache.
  """
  def get_session(session_id) do
    key = @session_prefix <> session_id

    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, data} -> {:ok, data}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Remove session from cache.
  """
  def delete_session(session_id) do
    key = @session_prefix <> session_id
    Cachex.del(@cache_name, key)
  end

  # Rate limiting functions

  @doc """
  Check and increment rate limit for an identifier.
  Returns {:ok, current_count} if allowed, {:error, :rate_limited} if exceeded.
  """
  def rate_limit(identifier, limit, window_seconds \\ 60) do
    key = @rate_limit_prefix <> identifier
    ttl = :timer.seconds(window_seconds)

    case Cachex.get(@cache_name, key) do
      {:ok, nil} ->
        # First request in window
        Cachex.put(@cache_name, key, 1, ttl: ttl)
        {:ok, 1}

      {:ok, count} when count < limit ->
        # Under limit, increment
        Cachex.incr(@cache_name, key, 1)
        {:ok, count + 1}

      {:ok, _count} ->
        # Over limit
        {:error, :rate_limited}

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Get current rate limit count for an identifier.
  """
  def get_rate_limit(identifier) do
    key = @rate_limit_prefix <> identifier

    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> {:ok, 0}
      {:ok, count} -> {:ok, count}
      {:error, _reason} = error -> error
    end
  end

  # General cache functions

  @doc """
  Get cache statistics.
  """
  def stats do
    Cachex.stats(@cache_name)
  end

  @doc """
  Get cache size.
  """
  def size do
    Cachex.size(@cache_name)
  end

  @doc """
  Clear all cache entries.
  """
  def clear do
    Cachex.clear(@cache_name)
  end

  @doc """
  Clear cache entries by pattern.
  """
  def clear_pattern(pattern) do
    Cachex.keys(@cache_name)
    |> case do
      {:ok, keys} ->
        keys
        |> Enum.filter(&String.contains?(&1, pattern))
        |> Enum.each(&Cachex.del(@cache_name, &1))

        :ok

      error ->
        error
    end
  end

  @doc """
  Warm up the cache with popular slugs.
  """
  def warm_up_slugs(popular_links) do
    popular_links
    |> Enum.each(fn {slug, original_url} ->
      # Longer TTL for popular links
      put_slug(slug, original_url, :timer.hours(48))
    end)
  end
end
