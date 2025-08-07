defmodule UrlShortenerWeb.AdminDashboardLive do
  use UrlShortenerWeb, :live_view

  def mount(_params, _session, socket) do
    current_admin = socket.assigns.current_admin
    {:ok, assign(socket, :current_admin, current_admin)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-bold">Admin Dashboard</h1>
      <p>Welcome, <%= @current_admin.name %>!</p>
      <a href="/admin/links" class="text-blue-500 hover:underline">
        Manage Links
      </a>
    </div>
    """
  end
end
