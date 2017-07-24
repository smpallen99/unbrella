defmodule <%= module %> do
  @doc """
  The main application file for <%= otp_app %>.
  """

  def children do
    import Supervisor.Spec, warn: false

    [
      # Enter services to start for this plug-in
      # worker(<%= module %>.Server, [])
    ]
  end

  def start(_type, _args) do
    @doc """
     Add initialize code below.
    """
    nil
  end

end
