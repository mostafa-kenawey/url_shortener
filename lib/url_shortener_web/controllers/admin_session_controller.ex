defmodule UrlShortenerWeb.AdminSessionController do
  @moduledoc """
  Controller for handling admin authentication sessions (login/logout).

  This controller manages:
  - Admin login with email and password authentication
  - Different login contexts (new registration, password update, regular login)
  - Session creation and management
  - Secure logout functionality
  - Protection against user enumeration attacks

  The controller works in conjunction with AdminAuth for session management
  and provides appropriate feedback messages for different login scenarios.
  """
  use UrlShortenerWeb, :controller

  alias UrlShortener.Admin
  alias UrlShortenerWeb.AdminAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:admin_return_to, ~p"/admin/dashboard")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"admin" => admin_params}, info) do
    handle_login(conn, admin_params, info)
  end

  defp create(conn, %{"account" => admin_params}, info) do
    handle_login(conn, admin_params, info)
  end

  defp handle_login(conn, admin_params, info) do
    %{"email" => email, "password" => password} = admin_params

    if admin = Admin.get_admin_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> AdminAuth.log_in_admin(admin, admin_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/admin/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AdminAuth.log_out_admin()
  end
end
