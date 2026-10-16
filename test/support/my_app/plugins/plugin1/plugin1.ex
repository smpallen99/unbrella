defmodule Plugin1 do
  @moduledoc false
  def children do
    [
      Plugin1.Service1,
      Plugin1.Service2
    ]
  end
end
