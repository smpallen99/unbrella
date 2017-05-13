defmodule Unbrella.Utils do
  @moduledoc false

  @doc false
  def get_modules(calling_mod) do
    get_schemas()
    |> Enum.map(fn mod ->
      Code.ensure_compiled(mod)
      mod
    end)
    |> Enum.reduce([], fn mod, acc ->
      case mod.schema_fields() do
        {^calling_mod, entry} ->
          [entry | acc]
        _ ->
          acc
      end
    end)
  end

  @doc false
  def get_schemas do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {_, list}, acc ->
      if mods = list[:schemas], do: acc ++ mods, else: acc
    end)
  end

  @doc false
  def get_migration_paths do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {plugin, list}, acc ->
      path = Path.join ["plugins", (list[:path] || to_string(plugin)) | ~w(priv repo migrations)]
      if File.exists?(path), do: [path | acc], else: acc
    end)
  end

  @doc false
  def get_seeds_paths do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {plugin, list}, acc ->
      path = Path.join ["plugins", (list[:path] || to_string(plugin)) | ~w(priv repo seeds.exs)]

      if File.exists?(path), do: [path | acc], else: acc
    end)
  end

end
