defmodule HukumSocketsWeb.GameChannel do
  use HukumSocketsWeb, :channel
  alias HukumSocketsWeb.Presence

  @impl true
  def join("game:" <> _game_name, %{"user_name" => user_name}, socket) do
    if number_of_players(socket) < 4 do
      send(self(), :after_join)
      {:ok, assign(socket, :user_name, user_name)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_name, %{
      online_at: inspect(System.system_time(:second))
    })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  defp number_of_players(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> length()
  end
end
