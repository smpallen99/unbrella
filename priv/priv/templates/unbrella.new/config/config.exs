import Config

config :unbrella, :plugins, <%= otp_app %>: [
  module: <%= module %>
]
