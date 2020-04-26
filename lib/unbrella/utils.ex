defmodule Unbrella.Utils do
  @moduledoc false
  import Mix.EctoSQL

  @doc false
  @spec get_modules(atom) :: List.t()
  def get_modules(calling_mod) do
    get_schemas()
    |> Enum.map(fn mod ->
      Code.ensure_compiled(mod)
      mod
    end)
    |> Enum.reduce([], fn mod, acc ->
      case mod.schema_fields() do
        {^calling_mod, entry} -> [entry | acc]
        _ -> acc
      end
    end)
  end

  @doc false
  @spec get_schemas() :: List.t()
  def get_schemas do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {_, list}, acc ->
      if mods = list[:schemas], do: acc ++ mods, else: acc
    end)
  end

  @doc false
  @spec get_migration_paths() :: [String.t()]
  def get_migration_paths do
    get_plugin_paths(~w(priv repo migrations))
  end

  @doc false
  @spec get_seeds_paths() :: [String.t()]
  def get_seeds_paths do
    get_plugin_paths(~w(priv repo seeds.exs))
  end

  @spec get_plugin_paths([String.t()]) :: [String.t()]
  def get_plugin_paths(paths \\ [""]) do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.reduce([], fn {plugin, list}, acc ->
      path = Path.join(["plugins", list[:path] || to_string(plugin) | paths])

      if File.exists?(path), do: [path | acc], else: acc
    end)
  end

  def get_plugins do
    Application.get_env(:unbrella, :plugins)
  end

  def get_assets_paths do
    Enum.reduce(get_plugins(), [], fn {name, config}, acc ->
      case config[:assets] do
        nil ->
          acc

        assets ->
          path = Path.join(["plugins", config[:path] || to_string(name), "assets"])

          Enum.map(assets, fn {src, dest} ->
            %{
              src: src,
              name: name,
              destination_path: Path.join(["assets", to_string(src), to_string(dest)]),
              source_path: Path.join([path, to_string(src)])
            }
          end) ++ acc
      end
    end)
  end

  def get_migrations(repo, _args \\ []) do
    priv_migrations_path = Path.join([source_repo_priv(repo), "migrations", "*"])

    base_paths =
      priv_migrations_path
      |> Path.wildcard()
      |> Enum.filter(&(Path.extname(&1) == ".exs"))

    plugin_paths =
      ["plugins", "*", priv_migrations_path]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.filter(&(Path.extname(&1) == ".exs"))

    build_migrate_files(base_paths ++ plugin_paths)
  end

  defp build_migrate_files(paths) do
    paths
    |> Enum.map(fn path ->
      [_, num] = Regex.run(~r/^([0-9]+)/, Path.basename(path))
      {num, path}
    end)
    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    |> List.foldr([], fn {num, path}, acc ->
      case Code.eval_file(path) do
        {{:module, mod, _, _}, _} ->
          [{String.to_integer(num), mod} | acc]

        other ->
          IO.puts("error for #{path}: " <> inspect(other))
          acc
      end
    end)
  end
end
