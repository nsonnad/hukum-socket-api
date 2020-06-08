defmodule HukumSocketsWeb.GameChannel do
  use HukumSocketsWeb, :channel
  alias HukumSocketsWeb.Presence
  alias HukumSockets.GameList
  require Protocol
  require Logger

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

    broadcast_game(socket)
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
        broadcast_game(socket)
        {:reply, :ok, socket}
      {:ok, _ } ->
        broadcast_game(socket)
        {:reply, :ok, socket}
      {:error, :team_full} ->
        {:reply, {:error, %{reason: "team_full" }}, socket}
    end
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info("#{socket.assigns.user_name} exiting game #{socket.assigns.game_name} with reason: #{inspect reason}")
    HukumEngine.remove_player(via(socket.assigns.game_name), socket.assigns.user_name)

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
      broadcast_game(socket)
    end

  end

  # TODO: randomly assign teams after a period of no choosing

  defp broadcast_game(socket) do
    broadcast(socket, "game_state", %{game: get_player_game(socket.assigns.game_name)})
  end

  defp get_player_game(game_name) do
    game = HukumEngine.get_game_state(via(game_name))
    %{ game | players: Keyword.values(game.players)}

    # TODO: remove hands of other players before sending down?
    #players =
      #game.players
      #|> Enum.each(fn {k, p} ->
        #if k == String.to_atom(socket.assigns.user_name) do
          #p
        #else
          #%{ p | hand: length(p.hand)}
        #end
      #end)

    #%{game | players: players}
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
