defmodule HukumSocketsWeb.GameChannel do
  use HukumSocketsWeb, :channel
  alias HukumSocketsWeb.Presence

  @impl true
  def join("game:" <> game_name, %{"user_name" => user_name}, socket) do
    if number_of_players(socket) < 4 do
      send(self(), :after_join)
      {:ok, %{ game: get_game(game_name)}, assign(socket, :user_name, user_name)}
    else
      {:error, %{reason: "game_full"}}
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

  defp get_game(game_name) do
    HukumEngine.get_game_state(via(game_name))
  end

  defp via(game_name), do: HukumEngine.GameServer.via_tuple(game_name)

  defp number_of_players(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> length()
  end
end
