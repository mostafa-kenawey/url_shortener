defmodule UrlShortener.AdminTest do
  use UrlShortener.DataCase

  alias UrlShortener.Admin

  describe "links" do
    alias UrlShortener.Admin.Link

    import UrlShortener.AdminFixtures

    @invalid_attrs %{original_url: nil, slug: nil}

    test "list_links/0 returns all links" do
      link = link_fixture()
      assert Admin.list_links() == [link]
    end

    test "get_link!/1 returns the link with given id" do
      link = link_fixture()
      assert Admin.get_link!(link.id) == link
    end

    test "create_link/1 with valid data creates a link" do
      valid_attrs = %{original_url: "https://example.com", slug: "some slug"}

      assert {:ok, %Link{} = link} = Admin.create_link(valid_attrs)
      assert link.original_url == "https://example.com"
      assert link.slug == "some slug"
    end

    test "create_link/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_link(@invalid_attrs)
    end

    test "update_link/2 with valid data updates the link" do
      link = link_fixture()
      update_attrs = %{original_url: "https://updated-example.com", slug: "some updated slug"}

      assert {:ok, %Link{} = link} = Admin.update_link(link, update_attrs)
      assert link.original_url == "https://updated-example.com"
      assert link.slug == "some updated slug"
    end

    test "update_link/2 with invalid data returns error changeset" do
      link = link_fixture()
      assert {:error, %Ecto.Changeset{}} = Admin.update_link(link, @invalid_attrs)
      assert link == Admin.get_link!(link.id)
    end

    test "delete_link/1 deletes the link" do
      link = link_fixture()
      assert {:ok, %Link{}} = Admin.delete_link(link)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_link!(link.id) end
    end

    test "change_link/1 returns a link changeset" do
      link = link_fixture()
      assert %Ecto.Changeset{} = Admin.change_link(link)
    end
  end

  describe "admin tokens" do
    alias UrlShortener.Admin.AdminToken

    test "verify_email_token_query/2 returns error for invalid token" do
      invalid_token = "invalid_token"
      assert AdminToken.verify_email_token_query(invalid_token, "confirm") == :error
    end

    test "verify_change_email_token_query/2 returns error for invalid token" do
      invalid_token = "invalid_token"

      assert AdminToken.verify_change_email_token_query(invalid_token, "change:test@example.com") ==
               :error
    end
  end
end
