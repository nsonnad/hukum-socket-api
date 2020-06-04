defmodule HukumSocketsWeb.Presence do
  use Phoenix.Presence,
    otp_app: :hukum_sockets,
    pubsub_server: HukumSockets.PubSub
end
