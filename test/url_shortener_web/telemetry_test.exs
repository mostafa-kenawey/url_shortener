defmodule UrlShortenerWeb.TelemetryTest do
  use ExUnit.Case

  test "metrics/0 returns a list of metrics" do
    metrics = UrlShortenerWeb.Telemetry.metrics()
    assert is_list(metrics)
    assert length(metrics) > 0
    assert Enum.all?(metrics, &match?(%Telemetry.Metrics.Summary{}, &1) || match?(%Telemetry.Metrics.Sum{}, &1))
  end
end
