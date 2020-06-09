defmodule HukumSocketsWeb.GameChannel do
  use HukumSocketsWeb, :channel
  alias HukumSocketsWeb.Presence
  alias HukumSockets.GameList
  require Protocol
  require Logger

  Protocol.derive(Jason.Encoder, HukumEngine.Player)
  Protocol.derive(Jason.Encoder, HukumEngine.Player)

  @impl true
  def join("game:" <> game_name, %{"user_name" => user_name}, socket) do
    if number_of_players(socket) < 4 do
      send(self(), :after_join)
      HukumEngine.add_player(via(game_name), String.to_atom(user_name))
      socket = assign_game(socket, game_name, user_name)
      {:ok, socket}
    else
      {:error, %{reason: "game_full"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_name, %{
      online_at: inspect(System.system_time(:second))
    })

    if number_of_players(socket) == 4 do
     GameList.set_open(socket.assigns.game_name, false)
    end

    broadcast_game(socket, get_game(socket.assigns.game_name))
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_in("choose_team", %{"team" => team}, socket) do
    case HukumEngine.choose_team(
      via(socket.assigns.game_name),
      socket.assigns.user_name,
      team
    ) do
      {:ok, %{team_counts: [2, 2] }} ->
        HukumEngine.confirm_teams(via(socket.assigns.game_name))
        broadcast_game(socket, get_game(socket.assigns.game_name))
        {:reply, :ok, socket}
      {:ok, _ } ->
        broadcast_game(socket, get_game(socket.assigns.game_name))
        {:reply, :ok, socket}
      {:error, :team_full} ->
        {:reply, {:error, %{reason: "team_full" }}, socket}
    end
  end

  def handle_in("call_or_pass", %{"choice" => choice}, socket) do
    case HukumEngine.call_or_pass(
      via(socket.assigns.game_name),
      socket.assigns.user_name,
      String.to_atom(choice)
    ) do
      {:ok, game} ->
        broadcast_game(socket, game)
        {:reply, :ok, socket}
      {:error, :not_your_turn} ->
        {:reply, {:error, %{reason: "not_your_turn"}}, socket}
      :error ->
        {:reply, :error, socket}
    end
  end

  def handle_in("call_trump", %{"trump" => trump}, socket) do
    case HukumEngine.call_trump(
      via(socket.assigns.game_name),
      socket.assigns.user_name,
      String.to_atom(trump)
    ) do
      {:ok, game} ->
        broadcast_game(socket, game)
        {:reply, :ok, socket}
      {:error, :not_your_turn} ->
        {:reply, {:error, %{reason: "not_your_turn"}}, socket}
      :error ->
        {:reply, :error, socket}
    end
  end

  def handle_in("play_card", %{"card" => %{"rank" => rank, "suit" => suit}}, socket) do
    case HukumEngine.play_card(
      via(socket.assigns.game_name),
      socket.assigns.user_name,
      %{ suit: String.to_atom(suit), rank: String.to_atom(rank) }
    ) do
      {:ok, game} ->
        broadcast_game(socket, game)
        {:reply, :ok, socket}
      {:error, :not_your_turn} ->
        {:reply, {:error, %{reason: "not_your_turn"}}, socket}
      {:error, :illegal_card} ->
        {:reply, {:error, %{reason: "illegal_card"}}, socket}
      :error ->
        {:reply, :error, socket}
    end
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info("#{socket.assigns.user_name} exiting game #{socket.assigns.game_name} with reason: #{inspect reason}")
    HukumEngine.remove_player(via(socket.assigns.game_name), socket.assigns.user_name)

    # clean up the game if this is the only/last person in the channel
    if number_of_players(socket) <= 1 do
      HukumEngine.end_game(via(socket.assigns.game_name))
      GameList.remove_game(socket.assigns.game_name)
      HukumSocketsWeb.Endpoint.broadcast_from!(
        self(),
        "lobby:lobby",
        "game_list",
        %{game_list: GameList.get_open_games() }
      )
    else
      broadcast_game(socket, get_game(socket.assigns.game_name))
    end

  end

  # TODO: randomly assign teams after a period of no choosing

  defp broadcast_game(socket, game) do
    broadcast(socket, "game_state", %{game: clean_game(game)})
  end

  defp get_game(game_name) do
    case HukumEngine.get_game_state(via(game_name)) do
      {:ok, game} -> game
      :error -> {:error, %{reason: "get_game_state_failed"}}
    end
  end

  defp clean_game(game) do
    %{ game | players: Keyword.values(game.players)}
  end

  defp assign_game(socket, game_name, user_name) do
    socket
    |> assign(:user_name, String.to_atom(user_name))
    |> assign(:game_name, game_name)
  end

  defp via(game_name), do: HukumEngine.GameServer.via_tuple(game_name)

  defp number_of_players(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> length()
  end
end
