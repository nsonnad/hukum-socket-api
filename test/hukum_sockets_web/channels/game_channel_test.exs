defmodule HukumSocketsWeb.GameChannelTest do
  use HukumSocketsWeb.ChannelCase
  alias HukumSockets.GameList

  #setup do
    #{:ok, _, socket} =
      #HukumSocketsWeb.UserSocket
      #|> socket("user_name", %{user_name: :assign})
      #|> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game", %{user_name: "test"})

    #%{socket: socket}
  #end

  test "broadcasts game state on join" do
    HukumEngine.new_game("test-game")

    {:ok, _, socket} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game", %{user_name: "test"})

    assert_broadcast "game_state", %{:game => _}
  end

  test "no more than 4 players can join channel/game" do
    GameList.add_game("test-game2", %{"user_name" => "test", "private" => false})
    HukumEngine.new_game("test-game2")

    {:ok, _, socket1} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game2", %{user_name: "player1"})

    {:ok, _, socket2} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game2", %{user_name: "player2"})

    {:ok, _, socket3} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game2", %{user_name: "player3"})

    {:ok, _, socket4} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game2", %{user_name: "player4"})

    game5 =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game2", %{user_name: "player5"})

    assert game5 == {:error, %{reason: "game_full"}}
  end

  test "after everyone joins and chooses a team we move to :call_or_pass phase" do
    GameList.add_game("test-game3", %{"user_name" => "player1", "private" => false})
    HukumEngine.new_game("test-game3")

    {:ok, _, socket1} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game3", %{user_name: "player1"})

    {:ok, _, socket2} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game3", %{user_name: "player2"})

    {:ok, _, socket3} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game3", %{user_name: "player3"})

    {:ok, _, socket4} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game3", %{user_name: "player4"})

    push socket1, "choose_team", %{team: 1}
    push socket2, "choose_team", %{team: 1}
    push socket3, "choose_team", %{team: 2}
    push socket4, "choose_team", %{team: 2}

    assert_broadcast("game_state", %{:game => %{"stage": :call_or_pass}})
  end
end
