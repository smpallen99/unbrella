defmodule Unbrella.IntegrationTest do
  use ExUnit.Case, async: false

  defmodule HookCallbacks do
    def double(value, _increment), do: value * 2
    def fail(_value), do: raise("halt should skip later hooks")
    def abort, do: :halt
    def value, do: :value
    def halt_value, do: {:halt, :halted}
    def cont_value, do: {:cont, :continued}
  end

  setup do
    config = Application.get_all_env(:unbrella)

    on_exit(fn ->
      Application.delete_env(:unbrella, :plugins)
      for {key, value} <- config, do: Application.put_env(:unbrella, key, value)
    end)

    :ok
  end

  test "plugin schema fields and changesets extend the main schema" do
    Code.compile_string("""
    defmodule Unbrella.IntegrationTest.Extension do
      use Unbrella.Plugin.Schema, Unbrella.IntegrationTest.User
      extend_schema Unbrella.IntegrationTest.User do
        field :test, :string, default: "test"
      end
      def changeset(changeset, attrs) do
        changeset
        |> cast(attrs, [:test])
        |> validate_required([:test])
      end
    end
    """)

    Application.put_env(:unbrella, :plugins,
      integration: [schemas: [__MODULE__.Extension, Plugin1.User]]
    )

    Code.compile_string("""
    defmodule Unbrella.IntegrationTest.User do
      use Unbrella.Schema
      schema "users" do
        field :name, :string
      end
      def changeset(user, attrs) do
        user
        |> Ecto.Changeset.cast(attrs, [:name])
        |> plugin_changesets(attrs, __MODULE__)
      end
    end
    """)

    user_module = compiled_module("User")
    user = struct(user_module)
    assert user.test == "test"
    changeset = user_module.changeset(user, %{name: "Name", test: "Updated"})
    assert changeset.valid?
    assert changeset.changes == %{name: "Name", test: "Updated"}
    refute user_module.changeset(user, %{test: nil}).valid?
  end

  test "plugin routes compile into a Phoenix router including nested resources" do
    for controller <- [
          __MODULE__.StatusController,
          __MODULE__.UserController,
          __MODULE__.PostController
        ] do
      Module.create(
        controller,
        quote(
          do:
            (
              def init(opts), do: opts
              def call(conn, _opts), do: Plug.Conn.send_resp(conn, 200, "plugin")
            )
        ),
        Macro.Env.location(__ENV__)
      )
    end

    Code.compile_string("""
    defmodule Unbrella.IntegrationTest.PluginRouter do
      use Unbrella.Router
      scope "/plugins", Unbrella.IntegrationTest do
        pipe_through :api
        get "/status", StatusController, :show, private: %{plugin: true}
        resources "/users", UserController, only: [:index, :show] do
          resources "/posts", PostController, only: [:show]
        end
      end
      scope path: "/v2", alias: Unbrella.IntegrationTest, as: :v2 do
        get "/status", StatusController, :show
      end
    end
    """)

    Application.put_env(:unbrella, :plugins, integration: [router: __MODULE__.PluginRouter])

    Code.compile_string("""
    defmodule Unbrella.IntegrationTest.MainRouter do
      use Phoenix.Router
      pipeline :api do
        plug :accepts, ["json"]
      end
      use Unbrella.Plugin.Router
    end
    """)

    router = compiled_module("MainRouter")
    routes = router.__routes__()

    assert Enum.any?(
             routes,
             &(&1.path == "/plugins/status" and &1.plug == __MODULE__.StatusController)
           )

    assert Enum.any?(routes, &(&1.path == "/plugins/users/:user_id/posts/:id"))

    conn =
      Plug.Test.conn(:get, "/plugins/status")
      |> then(&router.call(&1, []))

    assert conn.status == 200
    assert conn.resp_body == "plugin"
    assert conn.private.plugin
    assert Enum.any?(routes, &(&1.path == "/v2/status" and &1.helper == "v2_status"))
  end

  test "compiled hooks accumulate values and support continuation and halting" do
    Code.compile_string("""
    defmodule Unbrella.IntegrationTest.Plugin.Hooks do
      use Unbrella.Hooks, :add_hooks
      add_hook :transform, [:value, :increment] do
        {:cont, value + increment}
      end
      add_hook :transform, Unbrella.IntegrationTest.HookCallbacks, :double
      add_hook :stop, [:value] do
        {:halt, value + 1}
      end
      add_hook :stop, Unbrella.IntegrationTest.HookCallbacks, :fail
      add_hook Unbrella.IntegrationTest.HookCallbacks, :abort
      add_hook Unbrella.IntegrationTest.HookCallbacks, :value
      add_hook Unbrella.IntegrationTest.HookCallbacks, :halt_value
      add_hook Unbrella.IntegrationTest.HookCallbacks, :cont_value
      add_hook :ping, [] do
        :cont
      end
    end
    """)

    Application.put_env(:unbrella, :plugins, integration: [module: __MODULE__.Plugin])

    Code.compile_string("""
    defmodule Unbrella.IntegrationTest.MainHooks do
      use Unbrella.Hooks, :defhooks
      defhook :transform, 2, doc: "Transform a value"
      defhook :stop, 1
      defhook :ping, 0
      defhook :unchanged, 1
      defhook :abort, 0
      defhook :value, 0
      defhook :halt_value, 0
      defhook :cont_value, 0
    end
    """)

    hooks = compiled_module("MainHooks")
    assert hooks.transform(2, 3) == 10
    assert hooks.stop(2) == 3
    assert hooks.ping() == :ok
    assert hooks.unchanged(7) == 7
    assert hooks.abort() == :abort
    assert hooks.value() == :value
    assert hooks.halt_value() == :halted
    assert hooks.cont_value() == :continued
  end

  defp compiled_module(name), do: Module.concat(__MODULE__, name)
end
