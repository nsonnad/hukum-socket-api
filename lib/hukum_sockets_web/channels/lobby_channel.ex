defmodule HukumSocketsWeb.LobbyChannel do
  use HukumSocketsWeb, :channel
  alias HukumSocketsWeb.Presence
  alias HukumSockets.GameList

  @impl true
  def join("lobby:lobby", %{"user_name" => user_name}, socket) do
    if authorized?(socket, user_name) do
      send(self(), :after_join)
      {:ok, %{games: GameList.get_games()}, assign(socket, :user_name, user_name)}
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
  def handle_in("new_game", game_opts, socket) do
    game_name = Haiku.build(delimiter: "-", range: 99)
    case GameList.add_game(game_name, game_opts) do
      { :ok, new_list } ->
        broadcast(socket, "game_list", %{game_list: new_list})
        {:reply, { :ok, %{game_name: game_name} }, socket}
      {:error, :name_taken } ->
        {:reply, { :error, %{reason: "Game already exists"} }, socket}
    end
  end

  def handle_in("join_game", %{"game_name" => game_name}, socket) do
    case GameList.join_game(game_name) do
      :ok ->
        {:reply, :ok, socket}
      { :error, :game_does_not_exist } ->
        {:reply, { :error, %{reason: "game_does_not_exist"} }, socket}
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
