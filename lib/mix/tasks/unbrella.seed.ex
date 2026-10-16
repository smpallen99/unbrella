defmodule Mix.Tasks.Unbrella.Seed do
  use Mix.Task
  import Unbrella.Utils
  alias Mix.Tasks.Run

  @shortdoc "Runs the project and plugin seeds"
  @recursive true

  @moduledoc """
  Runs seeds for the given repository.


  """

  @doc false
  def run(_args) do
    # repos = parse_repo(args)
    # app =  Mix.Project.config[:app]

    Enum.each(["priv/repo/seeds.exs" | get_seeds_paths()], fn path ->
      Run.run([path])
    end)
  end
end
