defmodule <%= module %>.Mixfile do
  use Mix.Project

  def project do
    [
      app: :<%= otp_app %>,
      version: "0.1.0"
    ]
  end
end
