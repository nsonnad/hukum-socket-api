defmodule HukumSocketsWeb.LobbyChannelTest do
  use HukumSocketsWeb.ChannelCase
  alias HukumSockets.GameList

  setup do
    {:ok, _, socket} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.LobbyChannel, "lobby:lobby", %{user_name: "test"})

    %{socket: socket}
  end

  test "assigns username to socket after join", %{socket: socket} do
    assert socket.assigns.user_name == "test"
  end

  test "joining returns a list of games" do
    GameList.add_game("game1")
    GameList.add_game("game2")
    GameList.add_game("game3")
    GameList.add_game("game4")

    {:ok, resp, _socket} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.LobbyChannel, "lobby:lobby", %{user_name: "test2"})

    assert resp.games == GameList.get_games()
  end

  test "cannot join a game that doesn't exist", %{socket: socket} do
    ref = push socket, "join_game", %{game_name: "not_a_real_game"}
    assert_reply ref, :error, %{reason: "game_does_not_exist"}
  end

  test "create a new game, return its game_name, add it to GameList, and join it", %{socket: socket} do
    ref = push socket, "new_game"
    assert_reply ref, :ok, %{:game_name => _}
    game_name = Enum.random(GameList.get_games())

    {:ok, _, socket2} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.LobbyChannel, "lobby:lobby", %{user_name: "test2"})

    ref2 = push socket2, "join_game", %{game_name: game_name}
    assert_reply ref2, :ok, _
  end

  #test "broadcasts are pushed to the client", %{socket: socket} do
    #broadcast_from! socket, "broadcast", %{"some" => "data"}
    #assert_push "broadcast", %{"some" => "data"}
  #end
end
