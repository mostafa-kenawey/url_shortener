defmodule UrlShortener.DataCaseTest do
  use UrlShortener.DataCase

  test "errors_on/1 transforms changeset errors into a map" do
    changeset =
      %UrlShortener.Admin.Account{}
      |> UrlShortener.Admin.Account.registration_changeset(%{email: "invalid", password: "short"})

    errors = errors_on(changeset)

    assert is_map(errors)
    assert "must have the @ sign and no spaces" in errors.email
    assert "should be at least 12 character(s)" in errors.password
  end

  test "errors_on/1 handles changeset with no errors" do
    changeset =
      %UrlShortener.Admin.Account{}
      |> UrlShortener.Admin.Account.registration_changeset(%{
        name: "Test User",
        email: "test@example.com",
        password: "validpassword123"
      })

    errors = errors_on(changeset)
    assert errors == %{}
  end

  test "setup_sandbox/1 works with async tags" do
    assert :ok = UrlShortener.DataCase.setup_sandbox(%{async: true})
  end
end
