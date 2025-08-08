defmodule UrlShortenerWeb.PageController do
  @moduledoc """
  Controller for serving the main public pages of the URL shortener application.

  Currently handles:
  - Home page rendering without layout for landing page
  """
  use UrlShortenerWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
