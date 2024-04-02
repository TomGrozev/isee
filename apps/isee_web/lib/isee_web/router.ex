defmodule IseeWeb.Router do
  use IseeWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {IseeWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", IseeWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    live_session :authenticated, on_mount: [
      IseeWeb.Nav
    ] do
      live("/map", MapLive, :index)

      live("/cameras", CameraLive.Index, :index)
      live("/cameras/new", CameraLive.Index, :new)
      live("/cameras/import", CameraLive.Index, :import)
      live("/cameras/:id/edit", CameraLive.Index, :edit)

      live("/cameras/:id", CameraLive.Show, :show)
      live("/cameras/:id/show/edit", CameraLive.Show, :edit)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", IseeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:isee_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: IseeWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
