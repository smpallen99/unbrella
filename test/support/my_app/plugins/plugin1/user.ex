defmodule Plugin1.User do
  use Unbrella.Plugin.Schema, MyApp.User

  extend_schema MyApp.User do
    field :test, :string, default: "test"
  end
end