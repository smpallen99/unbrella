defmodule Unbrella.Plugin.Router do
  @moduledoc """
  Macro to bring plugin routers into your apps router.

  Imports the routes form each plugin into your main router. This is
  a simple helper that forwards "/" to each plugin's router.'

  If a plugin has a defined router, then you must add the router
  to your plugin's config file.

      # plugins/plugin1/config/config.exs
      use Mix.Config

      config :unbrella, :plugins, plugin1: [
        router: Plugin1.Web.Router
      ]

  You can then use this module like

      # lib/my_app/web/router.ex
      defmodule MyApp.Web.Router do
        use MyApp.Web, :router
        # ...
        scope "/", MyApp.Web do
          pipe_through :public
          get "/", HomeController, :index
        end

        # forward to each plugin
        use Unbrella.Plugin.Router
      end

  """

  @doc false
  defmacro __using__(_) do
    routers = routers()
    quote do
      Enum.each unquote(routers), fn mod ->
        forward "/", mod
      end
    end
  end

  @doc """
  Add the plugin routers to the main application router.

  Place this call at the end of your router to include any
  plugin routers that are configured in your plugin's config file


  ## Usage

  Add the call as the bottom of your main router.

      # lib/my_app/web/router.ex
      defmodule MyApp.Web.Router do
        use MyApp.Web, :router
        # ...
        scope "/", MyApp.Web do
          pipe_through :public
          get "/", HomeController, :index
        end

        # forward to each plugin
        use Unbrella.Plugin.Router
      end

  This will pickup the router configured in your plugin.

      defmodule UccChat.Web.Router do
        use Plugin1.Web, :router

        pipeline :browser do
          # ...
        end

        scope "/", Plugin1.Web do
          pipe_through :browser
          get "/avatar/:username", AvatarController, :show
        end
      end
  """
  def routers do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {_, list}, acc ->
      if router = list[:router], do: [router | acc], else: acc
    end)
  end
end
