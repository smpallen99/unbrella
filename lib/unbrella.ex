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

  require Logger

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
      [
        plugin1: [module: Plugin1, schemas: [Plugin1.User], router: Plugin1.Web.Router,
        plugin: Plugin1.Plugin, application: Plugin1], plugin2: []
      ]

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.apply_plugin_config()
      iex> Application.get_all_env(:plugin1) |> Keyword.equal?([
      ...> plugin: Plugin1.Plugin, schemas: [Plugin1.User], module: Plugin1,
      ...> router: Plugin1.Web.Router, application: Plugin1])
      true
  """
  def apply_plugin_config do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.each(fn {p, l} ->
      Enum.each(l, &(Application.put_env p, elem(&1,0), elem(&1, 1)))
    end)
  end

  @doc """
  Run the start/2 function for each plugin.

  Runs the start/2 function for all plugins that have defined an :application
  modules which exports :start/2.
  """
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

  @doc """
  Get all config values for a given key.

  Returns a list of `{plugin_name, value}` for each plugin that has the
  given config key with a non nil value.

  ## Examples

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.config_items(:module)
      [plugin1: Plugin1]

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.config_items(:invalid)
      []
  """
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

  @doc false
  def js_plugins do
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
  end

  @doc false
  def set_js_plugins(otp_app) do
    Application.put_env otp_app, :js_plugins, js_plugins()
  end

  @doc """
  Get the list of plugin modules.

  Returns a list of all the plugin modules.

  ## Examples

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.modules()
      [Plugin1]
  """
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

  @doc """
  Get the list of plugins that have defined a plugin configuration module.

  Filter the list of plugin modules for those plugins that have the `plugin`
  key set in their config.

  ## Examples

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.plugin_modules()
      [Plugin1.Plugin]
  """
  def plugin_modules do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {_, list}, acc ->
      if plugin_module = list[:plugin] do
        [plugin_module | acc]
      else
        acc
      end
    end)
  end

  @doc """
  Return the results of calling an arity 0 function on all plugin_modules.

  For each modules defining a Plugin Module, call the given function, returning
  a list of {result, plugin_module} tuples if the result of the calling the
  function is truthy.

  ## Options

  * :only_truthy (true) - Include only those results that are not nil or false
  * :only_results (false) - When set, only the results are returned, and not the
    {results, module_name}

  ## Examples

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_modules(:test1)
      [{:implemented, Plugin1.Plugin}]

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_modules(:test2)
      []

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_modules(:test2, only_truthy: false)
      [{nil, Plugin1.Plugin}]

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_modules(:test1, only_results: true)
      [:implemented]

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_modules(:test2, only_truthy: false, only_results: true)
      [nil]

  """
  def call_plugin_modules(function, opts \\ []) do
    plugin_modules()
    |> Enum.reduce([], fn mod, acc ->
      case {apply(mod, function, []), opts[:only_truthy]} do
        {result, false} ->
          [get_result(result, mod, opts[:only_results]) | acc]
        {result, _} when not result in [nil, false] ->
          [get_result(result, mod, opts[:only_results]) | acc]
        _ ->
          acc
      end
    end)
  end

  @doc """
  Call the given function/0 on the given plugin.

  Calls the given function on the plugin's module if one exists. Returns
  :error if the plugin module is found but the function is not exported.

  ## Examples:

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_module(:plugin1, :test1)
      :implemented

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_module(:plugin1, :test2)
      nil

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_module(:plugin1, :test3)
      :error

      iex> UnbrellaTest.Config.set_config!
      iex> Unbrella.call_plugin_module(:plugin2, :test3)
      nil
      iex> Unbrella.call_plugin_module(:plugin3, :test3)
      nil
  """
  def call_plugin_module(name, function, args \\ []) do
    arity = length(args)
    with plugins <- Application.get_env(:unbrella, :plugins),
         config when not is_nil(config) <- plugins[name],
         plugin_module when not is_nil(plugin_module) <- config[:plugin],
         true <- Code.ensure_compiled?(plugin_module),
         {true, :exported} <- {function_exported?(plugin_module, function, arity), :exported} do
      apply(plugin_module, function, args)
    else
      {false, :exported} -> :error
      _ -> nil
    end
  end

  @doc """
  Call the given function/0 on the given plugin.

  Same as `Unbrella.call_plugin_module/3' except it raises if the function
  is not exported.

  See `Unbrella.call_plugin_module/3' for more details.
  """
  def call_plugin_module!(name, function, args \\ []) do
    arity = length(args)
    case call_plugin_module(name, function, args) do
      :error -> raise("#{inspect function}/#{arity} is not exported")
      other -> other
    end
  end

  defp get_result(result, _mod, true), do: result
  defp get_result(result, mod, _), do: {result, mod}

  @doc """
  Get the hooks for each plugin exporting a hooks module.
  """
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
end
