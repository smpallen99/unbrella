defmodule UnbrellaTest do
  use ExUnit.Case
  doctest Unbrella

  setup do
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
      Unbrella.call_plugin_module!(:plugin1, :undefined) end
  end


end
