defmodule UrlShortener.RedirectMetricsTest do
  use UrlShortener.DataCase

  alias UrlShortener.RedirectMetrics.RedirectMetric
  alias UrlShortener.Admin
  import UrlShortener.AdminFixtures

  test "can create redirect metric with valid link_id" do
    # Create a link first
    link = link_fixture()

    # Create a redirect metric
    attrs = %{
      link_id: link.id,
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0 (Test Browser)"
    }

    changeset = RedirectMetric.changeset(%RedirectMetric{}, attrs)
    assert changeset.valid?

    {:ok, metric} = Repo.insert(changeset)
    assert metric.link_id == link.id
    assert metric.ip_address == "192.168.1.1"
    assert metric.user_agent == "Mozilla/5.0 (Test Browser)"
  end

  test "cannot create redirect metric with invalid link_id" do
    # Use a non-existent UUID
    invalid_uuid = Ecto.UUID.generate()

    attrs = %{
      link_id: invalid_uuid,
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0 (Test Browser)"
    }

    changeset = RedirectMetric.changeset(%RedirectMetric{}, attrs)
    assert changeset.valid?

    # Should fail due to foreign key constraint
    assert {:error, changeset} = Repo.insert(changeset)
    assert changeset.errors[:link_id]
  end

  test "deleting link cascades to redirect metrics" do
    link = link_fixture()

    # Create a redirect metric
    attrs = %{
      link_id: link.id,
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0 (Test Browser)"
    }

    {:ok, metric} =
      %RedirectMetric{}
      |> RedirectMetric.changeset(attrs)
      |> Repo.insert()

    # Verify metric exists
    assert Repo.get(RedirectMetric, metric.id)

    # Delete the link
    {:ok, _} = Admin.delete_link(link)

    # Metric should be deleted due to cascade
    refute Repo.get(RedirectMetric, metric.id)
  end
end
