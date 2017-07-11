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
    Enum.map get_plugin_paths(~w(test)), fn path ->
      Mix.shell.info "running tests for #{path}"
      Mix.Tasks.Test.run [path]
    end
  end
  def run(_), do: :ok
end
