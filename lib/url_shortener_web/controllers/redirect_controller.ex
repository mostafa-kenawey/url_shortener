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
        redirect(conn, external: link.original_url)
    end
  end
end
