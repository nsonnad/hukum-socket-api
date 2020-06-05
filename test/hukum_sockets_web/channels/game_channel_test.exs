defmodule HukumSocketsWeb.GameChannelTest do
  use HukumSocketsWeb.ChannelCase

  #setup do
    #{:ok, _, socket} =
      #HukumSocketsWeb.UserSocket
      #|> socket("user_name", %{user_name: :assign})
      #|> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game", %{user_name: "test"})

    #%{socket: socket}
  #end

  test "returns game state on join" do
    HukumEngine.new_game("test-game")

    {:ok, resp, socket} =
      HukumSocketsWeb.UserSocket
      |> socket("user_name", %{user_name: :assign})
      |> subscribe_and_join(HukumSocketsWeb.GameChannel, "game:test-game", %{user_name: "test"})

    assert resp.game.id == "test-game"
  end

  #test "shout broadcasts to game:lobby", %{socket: socket} do
    #push socket, "shout", %{"hello" => "all"}
    #assert_broadcast "shout", %{"hello" => "all"}
  #end

  #test "broadcasts are pushed to the client", %{socket: socket} do
    #broadcast_from! socket, "broadcast", %{"some" => "data"}
    #assert_push "broadcast", %{"some" => "data"}
  #end
end
