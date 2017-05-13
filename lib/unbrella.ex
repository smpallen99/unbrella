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
    |> Enum.reduce([], fn {plugin, list}, acc ->
      IO.puts "plugin: #{inspect plugin}"
      IO.puts "list: #{inspect list}"
      case list[:module] do
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
end
