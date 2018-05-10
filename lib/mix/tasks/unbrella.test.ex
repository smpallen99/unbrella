defmodule Mix.Tasks.Unbrella.Test do
  use Mix.Task
  import Unbrella.Utils

  @shortdoc "Run the plugins tests"
  @recursive true

  @moduledoc """
  Runs the tests for each of plugins
  """

  @doc false
  def run([]) do
     Mix.Tasks.Test.run(["test" | get_plugin_paths(~w(test))])
  end

  def run(list) do
     Mix.Tasks.Test.run(list)
  end
end
