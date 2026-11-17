defmodule MixHelper do
  @moduledoc false

  def in_tmp(which, function) do
    path = Path.expand("../../tmp/#{which}", __DIR__)
    File.rm_rf!(path)
    File.mkdir_p!(path)

    try do
      File.cd!(path, function)
    after
      File.rm_rf!(path)
    end
  end
end
