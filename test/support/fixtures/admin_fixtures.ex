defmodule UrlShortener.AdminFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `UrlShortener.Admin` context.
  """

  def random_admin_name, do: "Admin #{System.unique_integer()}"
  def unique_admin_email, do: "admin#{System.unique_integer()}@example.com"
  def valid_admin_password, do: "hello world!"

  def valid_admin_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: random_admin_name(),
      email: unique_admin_email(),
      password: valid_admin_password()
    })
  end

  def admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> valid_admin_attributes()
      |> UrlShortener.Admin.register_admin()

    admin
  end

  def extract_admin_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def link_fixture(attrs \\ %{}) do
    {:ok, link} =
      attrs
      |> Enum.into(%{
        original_url: "https://example.com",
        slug: "test-slug-#{System.unique_integer()}"
      })
      |> UrlShortener.Admin.create_link()

    link
  end
end
