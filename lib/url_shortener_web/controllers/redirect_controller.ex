defmodule UrlShortenerWeb.RedirectController do
  use UrlShortenerWeb, :controller

  alias UrlShortener.Links

  def show(conn, %{"slug" => slug}) do
    case Links.get_link_by_slug(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(html: UrlShortenerWeb.ErrorHTML)
        |> render("404.html")

      link ->
        user_agent = get_req_header(conn, "user-agent") |> List.first() || "unknown"
        ip = to_string(:inet_parse.ntoa(conn.remote_ip))

        # user_agent =
        #   conn
        #   |> Plug.Conn.get_req_header("user-agent")
        #   |> List.first()
        #   |> to_string()
        #   |> String.split(" ")
        #   |> List.first()
        #   |> Kernel.||("unknown")

        Phoenix.PubSub.broadcast(
          UrlShortener.PubSub,
          "redirect_events",
          {:redirect, %{
            link_id: link.id,
            ip_address: ip,
            user_agent: user_agent
          }}
        )

        redirect(conn, external: link.original_url)
    end
  end
end
