defmodule UrlShortenerWeb.AdminRegistrationLiveTest do
  use UrlShortenerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import UrlShortener.AdminFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_admin(admin_fixture())
        |> live(~p"/admin/register")
        |> follow_redirect(conn, "/admin/dashboard")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(admin: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end

    test "form validation with mixed valid and invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/register")

      # Test with some valid and some invalid data
      result =
        lv
        |> element("#registration_form")
        |> render_change(
          admin: %{"name" => "Valid Name", "email" => "valid@example.com", "password" => "short"}
        )

      assert result =~ "should be at least 12 character"
    end

    test "form validation with all valid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/register")

      # Test with all valid data (covers valid changeset branch)
      email = unique_admin_email()

      result =
        lv
        |> element("#registration_form")
        |> render_change(
          admin: %{"name" => "Valid Name", "email" => email, "password" => "valid_password_123"}
        )

      # Should not show any error messages
      refute result =~ "should be at least"
      refute result =~ "must have the @ sign"
    end
  end

  describe "register admin" do
    test "creates account and logs the admin in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/register")

      email = unique_admin_email()
      form = form(lv, "#registration_form", admin: valid_admin_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/admin/dashboard"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/register")

      admin = admin_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          admin: %{"email" => admin.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/log_in")

      assert login_html =~ "Log in"
    end
  end
end
