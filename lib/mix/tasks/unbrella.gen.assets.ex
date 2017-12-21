defmodule Mix.Tasks.Unbrella.Gen.Assets do
  use Mix.Task
  import Unbrella.Utils

  @shortdoc "Installs Plug-in Assets"
  @recursive true

  @moduledoc """
  Installs Plug-in Assets.

  ## Options

  `--all` - Generate assets for all configured plug-ins

  TODO: Add capability to specify individual plug-ins.

  ## Usage

      mix unbrella.gen.assets --all
  """

  @doc false
  def run(["--all"]) do
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

  def run(_) do
    Mix.shell.info "Usage: mix unbrella.gen.assets --all"
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
