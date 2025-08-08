defmodule UrlShortenerWeb.AdminLoginLiveTest do
  use UrlShortenerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import UrlShortener.AdminFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/log_in")

      assert html =~ "Log in"
      assert html =~ "Register"
      assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_admin(admin_fixture())
        |> live(~p"/admin/log_in")
        |> follow_redirect(conn, "/admin/dashboard")

      assert {:ok, _conn} = result
    end
  end

  describe "admin login" do
    test "redirects if admin login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      admin = admin_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/admin/log_in")

      form =
        form(lv, "#login_form",
          admin: %{email: admin.email, password: password, remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/admin/dashboard"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/log_in")

      form =
        form(lv, "#login_form",
          admin: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/admin/log_in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/log_in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/register")

      assert login_html =~ "Register"
    end

    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/log_in")

      {:ok, conn} =
        lv
        |> element("main a", "Forgot your password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/reset_password")

      assert conn.resp_body =~ "Forgot your password?"
    end
  end
end
