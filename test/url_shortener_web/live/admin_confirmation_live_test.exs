defmodule UrlShortenerWeb.AdminConfirmationLiveTest do
  use UrlShortenerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import UrlShortener.AdminsFixtures

  alias UrlShortener.Admins
  alias UrlShortener.Repo

  setup do
    %{admin: admin_fixture()}
  end

  describe "Confirm admin" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admins/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, admin: admin} do
      token =
        extract_admin_token(fn url ->
          Admins.deliver_admin_confirmation_instructions(admin, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/admins/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/admins/log_in")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Admin confirmed successfully"

      assert Admins.get_admin!(admin.id).confirmed_at
      refute get_session(conn, :admin_token)
      assert Repo.all(Admins.AdminToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/admins/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/admins/log_in")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Admin confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_admin(admin)

      {:ok, lv, _html} = live(conn, ~p"/admins/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/admins/log_in")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, admin: admin} do
      {:ok, lv, _html} = live(conn, ~p"/admins/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/admins/log_in")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Admin confirmation link is invalid or it has expired"

      refute Admins.get_admin!(admin.id).confirmed_at
    end
  end
end
