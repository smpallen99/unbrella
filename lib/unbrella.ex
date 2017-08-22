defmodule Unbrella do
  @moduledoc """
  Unbrella is a library to help Phoenix designers build an
  application that can be extended with plugins.

  Elixir's umbrella apps work will to package independent apps
  in a common project. Once way dependencies work wll with umbrella
  apps. However, if you need to share code bidirectionaly between two apps, you
  need a different solution.

  Unbrella is designed to allow plugins to extend the schema of a model
  defined in the main project. It allow allows inserting routers and
  plugin configuration.

  """

  @doc """
  Return list of the startup children for all plugins

  ## Examples

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.application_children()
      [{Plugin1, :children, []}]
  """
  def application_children do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {_plugin, list}, acc ->
      case list[:application] do
        nil -> acc
        module ->
          Code.ensure_compiled(module)
          if function_exported?(module, :children, 0) do
            [{module, :children, []} | acc]
          else
            acc
          end
      end
    end)
  end

  @doc """
  Allow access to plugin config by name

  i.e. Application.get_env(:ucc_ucx, :router)

  ## Examples

      iex> UnbrellaTest.Config.set_config!
      iex> Application.get_env(:unbrella, :plugins)
      [plugin1: [module: Plugin1, schemas: [Plugin1.User], router: Plugin1.Web.Router], plugin2: []]

      iex> Unbrella.apply_plugin_config()
      iex> Application.get_all_env(:plugin1) |> Keyword.equal?([schemas: [Plugin1.User], module: Plugin1, router: Plugin1.Web.Router])
      true
  """
  def apply_plugin_config do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.each(fn {p, l} ->
      Enum.each(l, &(Application.put_env p, elem(&1,0), elem(&1, 1)))
    end)
  end

  def start(type, args) do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.each(fn {_plugin, list} ->
      case list[:application] do
        nil -> nil
        module ->
          Code.ensure_compiled(module)
          if function_exported?(module, :start, 2) do
            apply module, :start, [type, args]
          end
      end
    end)
  end

  def config_items(key) do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {plugin, list}, acc ->
      case Keyword.get(list, key) do
        nil  -> acc
        item -> [{plugin, item} | acc]
      end
    end)
  end

  def js_plugins do
    plugins =
      :unbrella
      |> Application.get_env(:plugins)
      |> Enum.reduce([], fn {plugin, _}, acc ->
        plugin = to_string(plugin)
        if File.exists? Path.join(["plugins", plugin, "package.json"]) do
          [to_string(plugin) | acc]
        else
          acc
        end
      end)

    Application.put_env otp_app(), :js_plugins, plugins
  end

  def modules do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {_, list}, acc ->
      if module = list[:module] do
        [module | acc]
      else
        acc
      end
    end)
  end

  def hooks do
    modules()
    |> Enum.reduce([], fn module, acc ->
      module = Module.concat module, Hooks
      if function_exported? module, :hooks, 0 do
        module
        |> apply(:hooks, [])
        |> Enum.reduce(acc, fn {key, value}, acc ->
          update_in acc, [key], fn
            nil -> [value]
            entry -> [value | entry]
          end
        end)
      else
        acc
      end
    end)

  end

  @otp_app Mix.Project.config[:app]

  defp otp_app, do: @otp_app
end
