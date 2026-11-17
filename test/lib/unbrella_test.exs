defmodule UnbrellaTest do
  use ExUnit.Case
  doctest Unbrella

  setup do
    config = Application.get_all_env(:unbrella)
    plugin_config = Application.get_all_env(:plugin1)

    on_exit(fn ->
      for app <- [:unbrella, :plugin1],
          {key, _} <- Application.get_all_env(app),
          do: Application.delete_env(app, key)

      for {key, value} <- config, do: Application.put_env(:unbrella, key, value)
      for {key, value} <- plugin_config, do: Application.put_env(:plugin1, key, value)
    end)

    UnbrellaTest.Config.set_config!()
    :ok
  end

  test "call_plugin_modules undefined function" do
    assert Unbrella.call_plugin_modules(:undefined, only_results: true) == []
  end

  test "call_plugin_module undefined function" do
    assert Unbrella.call_plugin_module(:plugin1, :undefined, only_results: true) == :error
  end

  test "call_plugin_module! undefined function" do
    assert_raise RuntimeError, fn ->
      Unbrella.call_plugin_module!(:plugin1, :undefined)
    end
  end
end
