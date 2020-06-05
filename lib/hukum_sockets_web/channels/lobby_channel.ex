defmodule HukumSocketsWeb.LobbyChannel do
  use HukumSocketsWeb, :channel
  alias HukumSocketsWeb.Presence

  @impl true
  def join("lobby:lobby", %{"user_name" => user_name}, socket) do
    if authorized?(socket, user_name) do
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

  @impl true
  def handle_in("new_game", _payload, socket) do
    game_name = Haiku.build(delimiter: "_")
    case HukumEngine.new_game(game_name) do
      {:ok, _pid} -> {:reply, { :ok, %{game_name: game_name} }, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  #@impl true
  #def handle_in("shout", payload, socket) do
    #broadcast socket, "shout", payload
    #{:noreply, socket}
  #end

  # Add authorization logic here as required.
  defp authorized?(socket, user_name) do
    !existing_player?(socket, user_name)
  end

  defp existing_player?(socket, user_name) do
    socket
    |> Presence.list()
    |> Map.has_key?(user_name)
  end
end
