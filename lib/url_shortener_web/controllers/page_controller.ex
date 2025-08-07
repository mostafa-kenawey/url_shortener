defmodule UrlShortenerWeb.PageController do
  use UrlShortenerWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
