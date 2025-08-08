defmodule UrlShortenerWeb.AdminDashboardLive do
  use UrlShortenerWeb, :live_view
  alias UrlShortener.RedirectMetrics
  alias UrlShortener.Admin

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to redirect events for real-time updates
      Phoenix.PubSub.subscribe(UrlShortener.PubSub, "redirect_events")
      # Also refresh data every 30 seconds
      :timer.send_interval(30_000, self(), :refresh_data)
    end

    socket = 
      socket
      |> assign(:current_admin, socket.assigns.current_admin)
      |> load_dashboard_data()

    {:ok, socket}
  end

  def handle_info({:redirect, _payload}, socket) do
    # Real-time update when new redirects happen
    {:noreply, load_dashboard_data(socket)}
  end

  def handle_info(:refresh_data, socket) do
    # Periodic refresh
    {:noreply, load_dashboard_data(socket)}
  end
  
  def handle_info(_msg, socket) do
    # Handle unknown messages gracefully
    {:noreply, socket}
  end

  defp load_dashboard_data(socket) do
    socket
    |> assign(:total_clicks, RedirectMetrics.get_total_clicks())
    |> assign(:total_links, Admin.list_links() |> length())
    |> assign(:clicks_by_link, RedirectMetrics.get_clicks_by_link())
    |> assign(:browser_stats, RedirectMetrics.get_browser_stats())
    |> assign(:recent_clicks, RedirectMetrics.get_recent_clicks(15))
    |> assign(:clicks_over_time, RedirectMetrics.get_clicks_over_time(7))
    |> assign(:top_locations, RedirectMetrics.get_top_locations(10))
    |> assign(:last_updated, DateTime.utc_now())
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Header -->
      <div class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-6">
            <div>
              <h1 class="text-3xl font-bold text-gray-900">Analytics Dashboard</h1>
              <p class="text-sm text-gray-600 mt-1">Welcome back, <%= @current_admin.name %>!</p>
            </div>
            <div class="flex space-x-4">
              <div class="text-sm text-gray-500">
                Last updated: <%= Calendar.strftime(@last_updated, "%H:%M:%S") %>
              </div>
              <.link navigate={~p"/admin/links"} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                Manage Links
              </.link>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Key Metrics Row -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Total Clicks</p>
                <p class="text-3xl font-bold text-blue-600"><%= @total_clicks %></p>
              </div>
              <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.122 2.122"></path>
                </svg>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Total Links</p>
                <p class="text-3xl font-bold text-green-600"><%= @total_links %></p>
              </div>
              <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path>
                </svg>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Avg Clicks/Link</p>
                <p class="text-3xl font-bold text-purple-600">
                  <%= if @total_links > 0, do: Float.round(@total_clicks / @total_links, 1), else: "0" %>
                </p>
              </div>
              <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                </svg>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Active Today</p>
                <p class="text-3xl font-bold text-orange-600">
                  <%= Enum.count(@clicks_over_time, &(&1.date == Date.utc_today())) %>
                </p>
              </div>
              <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                <svg class="w-6 h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <!-- Charts Row -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <!-- Top Links Chart -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Top Performing Links</h3>
            <div class="space-y-4">
              <%= for {link, index} <- Enum.with_index(@clicks_by_link |> Enum.take(5)) do %>
                <div class="flex items-center justify-between">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      <%= link.slug %>
                    </p>
                    <p class="text-xs text-gray-500 truncate">
                      <%= link.original_url %>
                    </p>
                  </div>
                  <div class="ml-4 flex items-center">
                    <div class="flex-1 bg-gray-200 rounded-full h-2 w-24 mr-3">
                      <div class="bg-blue-600 h-2 rounded-full" style={"width: #{min(100, (link.click_count / max(1, @total_clicks)) * 100 * 5)}%"}></div>
                    </div>
                    <span class="text-sm font-medium text-gray-900"><%= link.click_count %></span>
                  </div>
                </div>
              <% end %>
              <%= if Enum.empty?(@clicks_by_link) do %>
                <p class="text-gray-500 text-center py-4">No data available yet</p>
              <% end %>
            </div>
          </div>

          <!-- Browser Stats -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Browser Usage</h3>
            <div class="space-y-3">
              <%= for browser <- @browser_stats do %>
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="w-3 h-3 rounded-full mr-3" style={browser_color(browser.browser)}></div>
                    <span class="text-sm font-medium text-gray-900"><%= browser.browser %></span>
                  </div>
                  <div class="flex items-center">
                    <div class="flex-1 bg-gray-200 rounded-full h-2 w-20 mr-3">
                      <div class="h-2 rounded-full" style={"#{browser_color(browser.browser)}; width: #{(browser.count / max(1, @total_clicks)) * 100}%"}></div>
                    </div>
                    <span class="text-sm font-medium text-gray-900"><%= browser.count %></span>
                  </div>
                </div>
              <% end %>
              <%= if Enum.empty?(@browser_stats) do %>
                <p class="text-gray-500 text-center py-4">No data available yet</p>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Recent Activity and Locations Row -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Recent Clicks -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h3>
            <div class="space-y-3 max-h-96 overflow-y-auto">
              <%= for click <- @recent_clicks do %>
                <div class="flex items-center justify-between py-2 border-b border-gray-100 last:border-b-0">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      <%= click.slug %>
                    </p>
                    <p class="text-xs text-gray-500 truncate">
                      <%= click.ip_address %>
                    </p>
                  </div>
                  <div class="text-xs text-gray-500">
                    <%= time_ago(click.inserted_at) %>
                  </div>
                </div>
              <% end %>
              <%= if Enum.empty?(@recent_clicks) do %>
                <p class="text-gray-500 text-center py-8">No activity yet</p>
              <% end %>
            </div>
          </div>

          <!-- Top Locations -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Top Locations (by IP)</h3>
            <div class="space-y-3">
              <%= for location <- @top_locations do %>
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center mr-3">
                      <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      </svg>
                    </div>
                    <span class="text-sm font-medium text-gray-900"><%= location.ip_address %></span>
                  </div>
                  <span class="text-sm font-medium text-gray-900 bg-gray-100 px-2 py-1 rounded"><%= location.count %></span>
                </div>
              <% end %>
              <%= if Enum.empty?(@top_locations) do %>
                <p class="text-gray-500 text-center py-4">No location data yet</p>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions
  defp browser_color("Chrome"), do: "background-color: #4285f4;"
  defp browser_color("Firefox"), do: "background-color: #ff9500;"
  defp browser_color("Safari"), do: "background-color: #007aff;"
  defp browser_color("Edge"), do: "background-color: #0078d4;"
  defp browser_color(_), do: "background-color: #6b7280;"

  defp time_ago(%NaiveDateTime{} = naive_datetime) do
    # Convert NaiveDateTime to DateTime assuming it's UTC
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")
    time_ago(datetime)
  end
  
  defp time_ago(%DateTime{} = datetime) do
    seconds_ago = DateTime.diff(DateTime.utc_now(), datetime, :second)
    
    cond do
      seconds_ago < 60 -> "#{seconds_ago}s ago"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> "#{div(seconds_ago, 86400)}d ago"
    end
  end
end
