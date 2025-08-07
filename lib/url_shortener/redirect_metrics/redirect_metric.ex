defmodule UrlShortener.RedirectMetrics.RedirectMetric do
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