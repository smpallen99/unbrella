Code.require_file("../mix_helpers.exs", __DIR__)

defmodule UnbrellaTest.Utils do
  use ExUnit.Case
  doctest Unbrella.Utils

  import MixHelper
  alias Unbrella.Utils

  setup do
    Application.put_env(:unbrella, :plugins, plugin_one: [], plugin_two: [])
    :ok
  end

  test "get_plugin_paths" do
    in_tmp("get_plugin_paths", fn ->
      mk_plugsins()
      assert Utils.get_plugin_paths() == ~w(plugins/plugin_two plugins/plugin_one)

      assert Utils.get_plugin_paths(~w(config)) ==
               ~w(plugins/plugin_two/config plugins/plugin_one/config)
    end)
  end

  test "get_migration_paths" do
    in_tmp("get_migration_paths", fn ->
      mk_plugsins()

      assert Utils.get_migration_paths() ==
               ~w(plugins/plugin_two/priv/repo/migrations plugins/plugin_one/priv/repo/migrations)
    end)
  end

  test "get_seeds_paths" do
    in_tmp("get_plugin_paths", fn ->
      mk_plugsins()
      File.touch("plugins/plugin_two/priv/repo/seeds.exs")
      assert Utils.get_seeds_paths() == ~w(plugins/plugin_two/priv/repo/seeds.exs)
    end)
  end

  defp mk_plugsins do
    :unbrella
    |> Application.get_env(:plugins)
    |> Enum.each(fn {plugin, _} ->
      Enum.each(~w(config test priv/repo/migrations), fn path ->
        File.mkdir_p!(Path.join(["plugins", to_string(plugin), path]))
      end)
    end)
  end
end
