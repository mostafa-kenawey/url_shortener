defmodule UrlShortener.Admin.AdminNotifier do
  @moduledoc """
  Email notification service for admin authentication workflows.

  This module handles sending various types of authentication emails to admin users including:
  - Account confirmation emails with verification links
  - Password reset instructions
  - Email change confirmation notifications

  All emails are sent using the configured mailer service and include appropriate
  links and instructions for the user to complete their authentication workflow.
  """
  import Swoosh.Email

  alias UrlShortener.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"UrlShortener", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(admin, url) do
    deliver(admin.email, "Confirmation instructions", """

    ==============================

    Hi #{admin.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a admin password.
  """
  def deliver_reset_password_instructions(admin, url) do
    deliver(admin.email, "Reset password instructions", """

    ==============================

    Hi #{admin.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a admin email.
  """
  def deliver_update_email_instructions(admin, url) do
    deliver(admin.email, "Update email instructions", """

    ==============================

    Hi #{admin.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
