defmodule UrlShortener.Mailer do
  @moduledoc """
  Email delivery service for UrlShortener application.

  This module configures the Swoosh mailer for sending emails throughout the application,
  particularly for admin authentication workflows like account confirmation, password resets,
  and email change notifications.
  """
  use Swoosh.Mailer, otp_app: :url_shortener
end
