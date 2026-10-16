defmodule Unbrella.TasksTest do
  use ExUnit.Case, async: false
  import MixHelper
  alias Mix.Tasks.Unbrella.{Gen.Assets, Migrate, New, Rollback, Seed}

  defmodule Adapter do
    def ensure_all_started(_config, _mode), do: {:ok, []}
  end

  defmodule Pool do
    def unboxed_run(_repo, fun) do
      send(self(), :unboxed_run)
      assert is_function(fun, 0)
      fun.()
    end
  end

  defmodule Repo do
    def config do
      [otp_app: :unbrella, priv: "priv/repo", pool: Application.get_env(:unbrella, :test_pool)]
    end

    def __adapter__, do: Unbrella.TasksTest.Adapter
    def start_link(_opts), do: Agent.start_link(fn -> nil end, name: __MODULE__)
    def stop, do: Agent.stop(__MODULE__)
  end

  setup do
    config = Application.get_all_env(:unbrella)
    Application.put_env(:unbrella, :plugins, first: [], second: [])

    on_exit(fn ->
      for {key, _} <- Application.get_all_env(:unbrella),
          do: Application.delete_env(:unbrella, key)

      for {key, value} <- config, do: Application.put_env(:unbrella, key, value)

      for module <- [
            __MODULE__.FirstMigration,
            __MODULE__.MainMigration,
            __MODULE__.SecondMigration
          ] do
        :code.purge(module)
        :code.delete(module)
      end
    end)

    :ok
  end

  for {task, direction, default} <- [{Migrate, :up, [all: true]}, {Rollback, :down, [step: 1]}] do
    test "#{task} discovers main and plugin migrations in version order" do
      in_tmp("#{unquote(direction)}_migrations", fn ->
        fixtures()

        migrator = fn repo, migrations, direction, opts ->
          assert repo == Repo
          assert direction == unquote(direction)

          assert migrations == [
                   {1, Unbrella.TasksTest.FirstMigration},
                   {2, Unbrella.TasksTest.MainMigration},
                   {3, Unbrella.TasksTest.SecondMigration}
                 ]

          for {key, value} <- unquote(default), do: assert(opts[key] == value)
          []
        end

        assert unquote(task).run(["-r", inspect(Repo)], migrator) == :ok
        refute Process.whereis(Repo)
      end)
    end
  end

  test "migration options preserve steps and quiet mode through the sandbox pool" do
    in_tmp("migration_options", fn ->
      fixtures()
      Application.put_env(:unbrella, :test_pool, Pool)

      assert Migrate.run(["-r", inspect(Repo), "--step", "2", "--quiet"], fn _, _, :up, opts ->
               assert opts[:step] == 2
               assert opts[:log] == false
               assert opts[:log_sql] == false
               []
             end) == :ok

      assert_received :unboxed_run
    end)
  end

  test "asset generation copies plugin assets to their configured destination" do
    in_tmp("assets", fn ->
      Application.put_env(:unbrella, :plugins, first: [path: "custom", assets: [js: "first"]])
      File.mkdir_p!("plugins/custom/assets/js")
      File.write!("plugins/custom/assets/js/plugin.js", "plugin")
      Assets.run(["--all"])
      assert File.read!("assets/js/first/plugin.js") == "plugin"
      File.write!("assets/js/first/old.js", "old")
      Assets.run(["--all"])
      refute File.exists?("assets/js/first/old.js")
    end)
  end

  test "asset generation reports missing source directories" do
    in_tmp("missing_assets", fn ->
      Application.put_env(:unbrella, :plugins, first: [assets: [js: "first"]])

      assert_raise Mix.Error, ~r/Cannot find path/, fn ->
        Assets.run(["--all"])
      end
    end)
  end

  test "new plugin task validates the name" do
    assert_raise Mix.Error, "Must provide a name", fn -> New.run([]) end
    assert_raise Mix.Error, ~r/Invalid arguments/, fn -> New.run(["first", "second"]) end
    assert New.run(["example"]) == :ok
  end

  test "seed task runs the main and plugin seed scripts" do
    in_tmp("seeds", fn ->
      for folder <- ["priv/repo", "plugins/first/priv/repo"] do
        File.mkdir_p!(folder)
        File.write!(Path.join(folder, "seeds.exs"), "send(self(), {:seeded, #{inspect(folder)}})")
      end

      Seed.run([])
      assert_received {:seeded, "priv/repo"}
      assert_received {:seeded, "plugins/first/priv/repo"}
    end)
  end

  defp fixtures do
    for {folder, version, name} <- [
          {"priv/repo/migrations", "002", "MainMigration"},
          {"plugins/first/priv/repo/migrations", "001", "FirstMigration"},
          {"plugins/second/priv/repo/migrations", "003", "SecondMigration"}
        ] do
      File.mkdir_p!(folder)

      File.write!(Path.join(folder, "#{version}_migration.exs"), """
      defmodule Unbrella.TasksTest.#{name} do
        use Ecto.Migration
        def change, do: :ok
      end
      """)
    end
  end
end
