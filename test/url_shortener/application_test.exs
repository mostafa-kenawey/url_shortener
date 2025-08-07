defmodule UrlShortener.ApplicationTest do
  use ExUnit.Case

  test "config_change/3 returns :ok" do
    assert UrlShortener.Application.config_change(%{}, %{}, []) == :ok
  end
end
