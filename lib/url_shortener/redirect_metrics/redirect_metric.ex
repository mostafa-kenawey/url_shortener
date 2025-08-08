defmodule UrlShortener.RedirectMetrics.RedirectMetric do
  @moduledoc """
  Schema for storing redirect event analytics data.

  This module defines the structure for tracking individual redirect events,
  capturing essential information for analytics:
  - Associated link that was redirected
  - IP address of the visitor (for geographic and usage analysis)
  - User agent string (for device and browser analytics)
  - Timestamp of the redirect event

  Each metric record represents a single redirect event and is used to generate
  analytics reports and insights about link usage patterns.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary_id
  schema "redirect_metrics" do
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :link, UrlShortener.Admin.Link

    timestamps(updated_at: false)
  end

  def changeset(metric, attrs) do
    metric
    |> cast(attrs, [:link_id, :ip_address, :user_agent])
    |> validate_required([:link_id, :ip_address, :user_agent])
    |> foreign_key_constraint(:link_id)
  end
end
