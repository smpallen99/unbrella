defmodule Unbrella.Router do
  @moduledoc """
  Router macros for defining plugin routes.

  This module provides the a subset of the Phoenix Router API for defining routes
  for an Unbrella plugin.

  ## Examples

      defmodule MyPluginWeb.Router do
        use Unbrella.Router

        scope "/", MyPluginWeb do
          pipe_through :browser

          get "/test", TestController, :index
          get "/test/:id", TestController, :show
          post "/test", TestController, :create
        end
      end

      defmodule MyUnbrellaAppWeb.Router do
        use MyUnbrellaAppWeb, :router

        pipeline :browser do
          plug(:accepts, ["html", "md"])
          plug(:fetch_session)
          plug(:fetch_flash)
          plug(:protect_from_forgery)
          plug(:put_secure_browser_headers)
        end

        pipeline :api do
          plug(:accepts, ["json"])
        end

        scope "/", MyUnbrellaAppWeb do
          pipe_through :browser

          get "/", HomeController, :index
        end

        # include all the plugins that have defined a router
        use Unbrella.Plugin.Router
      end

      # will provide the following helpers

      * MyUnbrellaAppWeb.Router.Helpers:
        * `home_path`, `home_url`
        * `test_path`, `test_path`
  """

  @http_methods [:get, :post, :put, :patch, :delete, :options, :connect, :trace, :head]

  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :scopes, persist: true, accumulate: true)
      Module.register_attribute(__MODULE__, :pipes, persist: false, accumulate: false)
      Module.register_attribute(__MODULE__, :matches, persist: false, accumulate: false)
      Module.register_attribute(__MODULE__, :resources, persist: false, accumulate: false)
      Module.put_attribute(__MODULE__, :pipes, [])
      Module.put_attribute(__MODULE__, :matches, [])
      Module.put_attribute(__MODULE__, :resources, [])
    end
  end

  defmacro scope(path, options, do: block) do
    add_scope(path, options, block)
  end

  defmacro scope(options, do: block) do
    add_scope(nil, options, block)
  end

  defmacro scope(path, alias, options, do: block) do
    options = quote do
      unquote(options)
      |> Keyword.put(:path, unquote(path))
      |> Keyword.put(:alias, unquote(alias))
    end
    add_scope(nil, options, block)
  end

  defp add_scope(path, options, block) do
    quote location: :keep do
      unquote(block)
      pipes = Module.get_attribute(__MODULE__, :pipes) |> Enum.reverse()
      matches = Module.get_attribute(__MODULE__, :matches) |> Enum.reverse()
      resources = Module.get_attribute(__MODULE__, :resources) |> Enum.reverse()
      Module.put_attribute(__MODULE__, :pipes, [])
      Module.put_attribute(__MODULE__, :matches, [])
      Module.put_attribute(__MODULE__, :resources, [])
      path = unquote(path)
      options = unquote(options)
      scope_value = if is_nil(path), do: options, else: {path, options}
      scope = %{
        scope: scope_value,
        pipe_through: pipes,
        matches: matches,
        resources: resources
      }
      Module.put_attribute __MODULE__, :scopes, scope
    end
  end

  defmacro pipe_through(options) do
    quote do
      Module.put_attribute(__MODULE__, :pipes, [unquote(options) | Module.get_attribute(__MODULE__, :pipes)])
    end
  end

  defmacro resources(path, controller) do
    add_resources(path, controller, [])
  end

  defmacro resources(path, controller, do: block) do
    add_resources(path, controller, [], block)
  end

  defmacro resources(path, controller, options) do
    add_resources(path, controller, options)
  end

  defmacro resources(path, controller, options, do: block) do
    add_resources(path, controller, options, block)
  end

  defp add_resources(path, controller, options) do
    quote do
      Module.put_attribute(__MODULE__, :resources,
        [{unquote(path), unquote(controller), unquote(options)} | Module.get_attribute(__MODULE__, :resources)])
    end
  end

  defp add_resources(path, controller, options, block) do
    quote do
      resources1 = Module.get_attribute(__MODULE__, :resources)
      Module.put_attribute(__MODULE__, :resources, [])
      unquote(block)
      resources2 = Module.get_attribute(__MODULE__, :resources) |> Enum.reverse()

      Module.put_attribute(__MODULE__, :resources,
        [{unquote(path), unquote(controller), unquote(options), resources2} | resources1])
    end
  end

  defmacro match(verb, path, plug, plug_opts, options \\ []) do
    add_match(verb, path, plug, plug_opts, options)
  end

  for verb <- @http_methods do
    defmacro unquote(verb)(path, plug, plug_opts, options \\ []) do
      add_match(unquote(verb), path, plug, plug_opts, options)
    end
  end

  defp add_match(verb, path, plug, plug_opts, options) do
    quote do
      match = {unquote(verb), unquote(path), unquote(plug), unquote(plug_opts), unquote(options)}
      Module.put_attribute(__MODULE__, :matches, [match | Module.get_attribute(__MODULE__, :matches)])
    end
  end

  defmacro __before_compile__(_) do
    quote unquote: false do
      def get_scopes, do: Enum.reverse(@scopes)
    end
  end
end
