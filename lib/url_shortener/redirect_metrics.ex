defmodule UrlShortener.RedirectMetrics do
  alias UrlShortener.Repo
  alias UrlShortener.RedirectMetrics.RedirectMetric

  def create_metric(attrs) do
    %RedirectMetric{}
    |> RedirectMetric.changeset(attrs)
    |> Repo.insert()
  end
end
