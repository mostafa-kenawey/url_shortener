defmodule UrlShortenerWeb.Admin.LinkLiveTest do
  use UrlShortenerWeb.ConnCase

  import Phoenix.LiveViewTest
  import UrlShortener.AdminFixtures

  @create_attrs %{original_url: "https://example.com", slug: "some slug"}
  @update_attrs %{original_url: "https://updated-example.com", slug: "some updated slug"}
  @invalid_attrs %{original_url: nil, slug: nil}

  defp create_link(_) do
    link = link_fixture()
    %{link: link}
  end

  describe "Index" do
    setup [:register_and_log_in_admin, :create_link]

    test "lists all links", %{conn: conn, link: link} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/links")

      assert html =~ "Listing Links"
      assert html =~ link.original_url
    end

    test "saves new link", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/links")

      assert index_live |> element("a", "New Link") |> render_click() =~
               "New Link"

      assert_patch(index_live, ~p"/admin/links/new")

      assert index_live
             |> form("#link-form", link: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#link-form", link: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/links")

      html = render(index_live)
      assert html =~ "Link created successfully"
      assert html =~ "https://example.com"
    end

    test "updates link in listing", %{conn: conn, link: link} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/links")

      assert index_live |> element("#links-#{link.id} a", "Edit") |> render_click() =~
               "Edit Link"

      assert_patch(index_live, ~p"/admin/links/#{link}/edit")

      assert index_live
             |> form("#link-form", link: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#link-form", link: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/links")

      html = render(index_live)
      assert html =~ "Link updated successfully"
      assert html =~ "https://updated-example.com"
    end

    test "deletes link in listing", %{conn: conn, link: link} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/links")

      assert index_live |> element("#links-#{link.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#links-#{link.id}")
    end

    test "handles form component saved message", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/links")

      # Simulate the message sent by FormComponent when a link is saved
      link = link_fixture()
      send(index_live.pid, {UrlShortenerWeb.Admin.LinkLive.FormComponent, {:saved, link}})

      # Verify the link appears in the stream
      assert render(index_live) =~ link.original_url
    end

    test "navigates to show page when clicking on link", %{conn: conn, link: link} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/links/#{link}")
      assert html =~ "Show Link"
      assert html =~ link.original_url
    end
  end

  describe "Show" do
    setup [:register_and_log_in_admin, :create_link]

    test "displays link", %{conn: conn, link: link} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/links/#{link}")

      assert html =~ "Show Link"
      assert html =~ link.original_url
    end

    test "updates link within modal", %{conn: conn, link: link} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/links/#{link}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Link"

      assert_patch(show_live, ~p"/admin/links/#{link}/show/edit")

      assert show_live
             |> form("#link-form", link: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#link-form", link: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/links/#{link}")

      html = render(show_live)
      assert html =~ "Link updated successfully"
      assert html =~ "https://updated-example.com"
    end
  end
end
