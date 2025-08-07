defmodule UrlShortenerWeb.Router do
  use UrlShortenerWeb, :router

  import UrlShortenerWeb.AdminAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UrlShortenerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UrlShortenerWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/:slug", RedirectController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", UrlShortenerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:url_shortener, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: UrlShortenerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", UrlShortenerWeb do
    pipe_through [:browser, :redirect_if_admin_is_authenticated]

    live_session :redirect_if_admin_is_authenticated,
      on_mount: [{UrlShortenerWeb.AdminAuth, :redirect_if_admin_is_authenticated}] do
      live "/admin/register", AdminRegistrationLive, :new
      live "/admin/log_in", AdminLoginLive, :new
      live "/admin/reset_password", AdminForgotPasswordLive, :new
      live "/admin/reset_password/:token", AdminResetPasswordLive, :edit
    end

    post "/admin/log_in", AdminSessionController, :create
  end

  scope "/", UrlShortenerWeb do
    pipe_through [:browser, :require_authenticated_admin]

    live_session :require_authenticated_admin,
      on_mount: [{UrlShortenerWeb.AdminAuth, :ensure_authenticated}] do
      live "/admin/settings", AdminSettingsLive, :edit
      live "/admin/settings/confirm_email/:token", AdminSettingsLive, :confirm_email

      live "/admin/dashboard", AdminDashboardLive

      live "/admin/links", Admin.LinkLive.Index, :index
      live "/admin/links/new", Admin.LinkLive.Index, :new
      live "/admin/links/:id/edit", Admin.LinkLive.Index, :edit

      live "/admin/links/:id", Admin.LinkLive.Show, :show
      live "/admin/links/:id/show/edit", Admin.LinkLive.Show, :edit
    end
  end

  scope "/", UrlShortenerWeb do
    pipe_through [:browser]

    delete "/admin/log_out", AdminSessionController, :delete

    live_session :current_admin,
      on_mount: [{UrlShortenerWeb.AdminAuth, :mount_current_admin}] do
      live "/admin/confirm/:token", AdminConfirmationLive, :edit
      live "/admin/confirm", AdminConfirmationInstructionsLive, :new
    end
  end
end
