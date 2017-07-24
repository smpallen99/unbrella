defmodule Mix.Tasks.Unbrella.New do
  @moduledoc """
  Create a new plugin.
  """
  use Mix.Task

  @boolean_options ~w()a

  # complete list of supported options
  @switches [
  ] ++ Enum.map(@boolean_options, &({&1, :boolean}))

  def run(args) do
    {opts, parsed, _unknown} = OptionParser.parse(args, switches: @switches)

    opts
    |> parse_options(parsed)
    |> do_config(args)
    |> do_run
  end

  def do_run(config) do
    IO.inspect config.name, label: "Name"

  end

  defp do_config({_bin_opts, _opts, parsed}, _raw_args) do
    name =
      case parsed do
        [name] ->
          name
        [] ->
          Mix.raise "Must provide a name"
        other ->
          Mix.raise "Invalid arguments #{inspect other}"
      end

    %{
      name: name,
    }
  end

  defp parse_options([], parsed) do
    {[], [], parsed}
  end

  defp parse_options(opts, parsed) do
    bin_opts = Enum.filter(opts, fn {k,_v} -> k in @boolean_options end)
    {bin_opts, opts -- bin_opts, parsed}
  end

  defp paths do
    [".", :unbrella]
  end
end
