defmodule UrlShortener.RedirectMetrics do
  import Ecto.Query
  alias UrlShortener.Repo
  alias UrlShortener.RedirectMetrics.RedirectMetric
  alias UrlShortener.Admin.Link

  def create_metric(attrs) do
    %RedirectMetric{}
    |> RedirectMetric.changeset(attrs)
    |> Repo.insert()
  end

  def get_total_clicks do
    Repo.aggregate(RedirectMetric, :count)
  end

  def get_clicks_by_link do
    query = 
      from m in RedirectMetric,
      join: l in Link, on: m.link_id == l.id,
      group_by: [l.id, l.slug, l.original_url],
      select: %{
        link_id: l.id,
        slug: l.slug, 
        original_url: l.original_url,
        click_count: count(m.id),
        latest_click: max(m.inserted_at)
      },
      order_by: [desc: count(m.id)]
    
    Repo.all(query)
  end

  def get_browser_stats do
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
    
    Repo.all(query)
  end

  def get_recent_clicks(limit \\ 10) do
    query = 
      from m in RedirectMetric,
      join: l in Link, on: m.link_id == l.id,
      select: %{
        slug: l.slug,
        original_url: l.original_url, 
        ip_address: m.ip_address,
        user_agent: m.user_agent,
        inserted_at: m.inserted_at
      },
      order_by: [desc: m.inserted_at],
      limit: ^limit
    
    Repo.all(query)
  end

  def get_clicks_over_time(days \\ 7) do
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
    
    Repo.all(query)
  end

  def get_top_locations(limit \\ 10) do
    query = 
      from m in RedirectMetric,
      select: %{
        ip_address: m.ip_address,
        count: count(m.id)
      },
      group_by: m.ip_address,
      order_by: [desc: count(m.id)],
      limit: ^limit
    
    Repo.all(query)
  end
end
