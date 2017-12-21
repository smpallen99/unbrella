defmodule Mix.Tasks.Unbrella.Assets do
  use Mix.Task
  import Unbrella.Utils

  @shortdoc "Installs Plugin Assets"
  @recursive true

  @moduledoc """
  Installs Plugin Assets


  """

  @doc false
  def run(_args) do
    # IO.inspect args, label: "args"
    # repos = parse_repo(args)
    # app =  Mix.Project.config[:app]
    get_assets_paths()
    |> Enum.each(fn map ->
      map
      |> test_source!
      |> mk_destination!
      |> rm_destination!
      |> cp_files!
      Mix.shell.info "#{map[:name]} #{map[:src]} files copied."
    end)
  end

  defp test_source!(map) do
    unless File.exists? map[:source_path] do
      Mix.raise "Cannot find path #{map[:source_path]}"
    end
    map
  end

  defp mk_destination!(map) do
    case File.mkdir_p(map.destination_path) do
      :ok -> map
      _ ->
        Mix.raise "Could not create destination folder #{map[:destination_path]}"
    end
  end

  defp rm_destination!(map) do
    case File.rm_rf(map.destination_path) do
      {:ok, _} -> map
      _ ->
        Mix.raise "Could not remove destination folder #{map[:destination_path]}"
    end
  end

  defp cp_files!(map) do
    case File.cp_r map.source_path, map.destination_path do
      {:ok, _files} -> map
      _ ->
        Mix.raise "Could not copy files from folder #{map[:source_path]} to #{map[:destination_path]}"
    end
  end

end
