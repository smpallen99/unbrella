defmodule Unbrella.Plugin.Router do
  @moduledoc """
  Macro to bring plugin routers into your apps router.

  Imports the routes form each plugin into your main router. This is
  a simple helper that forwards "/" to each plugin's router.'

  If a plugin has a defined router, then you must add the router
  to your plugin's config file.

      # plugins/plugin1/config/config.exs
      import Config

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
    scopes =
      for router <- routers(),
          scope <- plugin_scopes(router) do
        {path, options} =
          case scope.scope do
            list when is_list(list) -> Keyword.pop(list, :path)
            tuple when is_tuple(tuple) -> tuple
          end

        pipes = for pipe <- scope.pipe_through, do: quote(do: pipe_through(unquote(pipe)))

        matches =
          for {verb, path, plug, plug_opts, options} <- scope.matches do
            quote do
              match(
                unquote(verb),
                unquote(path),
                unquote(plug),
                unquote(Macro.escape(plug_opts)),
                unquote(Macro.escape(options))
              )
            end
          end

        resources = Enum.map(scope.resources, &resource_ast/1)

        quote do
          scope unquote(path), unquote(Macro.escape(options)) do
            unquote_splicing(pipes)
            unquote_splicing(matches)
            unquote_splicing(resources)
          end
        end
      end

    quote do
      (unquote_splicing(scopes))
    end
  end

  defp plugin_scopes(router) do
    Code.ensure_compiled!(router)
    router.get_scopes()
  end

  defmacro do_resources(resource), do: resource_ast(resource)

  defp resource_ast({path, module, options}) do
    quote do
      resources(unquote(path), unquote(module), unquote(Macro.escape(options)))
    end
  end

  defp resource_ast({path, module, options, nested}) do
    children = Enum.map(nested, &resource_ast/1)

    quote do
      resources unquote(path), unquote(module), unquote(Macro.escape(options)) do
        (unquote_splicing(children))
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
