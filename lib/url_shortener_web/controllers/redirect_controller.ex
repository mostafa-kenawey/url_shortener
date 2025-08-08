defmodule UrlShortenerWeb.RedirectController do
  @moduledoc """
  Controller responsible for handling URL redirects from shortened links.

  This controller:
  - Implements rate limiting to prevent abuse (10 requests per minute per IP)
  - Uses caching for fast slug-to-URL lookups
  - Falls back to database queries for cache misses
  - Broadcasts redirect events for analytics tracking
  - Handles IP extraction from headers for load balancer compatibility
  - Tracks user agents and other metadata for analytics

  The redirect process is optimized for performance with Redis caching while
  maintaining accurate analytics through PubSub event broadcasting.
  """
  use UrlShortenerWeb, :controller
  require Logger

  alias UrlShortener.{Links, Cache}

  # Max requests per minute
  @rate_limit_requests 10
  # 60 seconds window
  @rate_limit_window 60

  def show(conn, %{"slug" => slug}) do
    # Rate limiting by IP
    ip = get_client_ip(conn)

    case Cache.rate_limit(ip, @rate_limit_requests, @rate_limit_window) do
      {:error, :rate_limited} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limit exceeded"})

      {:ok, _count} ->
        handle_redirect(conn, slug, ip)
    end
  end

  defp handle_redirect(conn, slug, ip) do
    # Try to get from cache first
    case Cache.get_slug(slug) do
      {:ok, original_url} ->
        Logger.debug("Cache hit for slug: #{slug}")
        broadcast_and_redirect(conn, slug, original_url, ip, cache_hit: true)

      {:error, :not_found} ->
        # Cache miss, query database
        Logger.debug("Cache miss for slug: #{slug}")

        case Links.get_link_by_slug(slug) do
          nil ->
            conn
            |> put_status(:not_found)
            |> put_view(html: UrlShortenerWeb.ErrorHTML)
            |> render("404.html")

          link ->
            # Cache the result for future requests
            Cache.put_slug(slug, link.original_url)

            broadcast_and_redirect(conn, slug, link.original_url, ip,
              cache_hit: false,
              link_id: link.id
            )
        end
    end
  end

  defp broadcast_and_redirect(conn, _slug, original_url, ip, opts) do
    user_agent = get_user_agent(conn)

    # Only broadcast if we have link_id (from DB query, not cache)
    if link_id = opts[:link_id] do
      payload = {
        :redirect,
        %{
          link_id: link_id,
          ip_address: ip,
          user_agent: user_agent
        }
      }

      case Phoenix.PubSub.broadcast(UrlShortener.PubSub, "redirect_events", payload) do
        :ok -> :ok
        error -> Logger.error("Failed to broadcast redirect event: #{inspect(error)}")
      end
    end

    redirect(conn, external: original_url)
  end

  defp get_client_ip(conn) do
    # Check for forwarded IP first (for load balancers/proxies)
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded_ip | _] ->
        forwarded_ip
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        # Fall back to remote IP
        to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end

  defp get_user_agent(conn) do
    get_req_header(conn, "user-agent")
    |> List.first()
    |> Kernel.||("unknown")
  end
end
