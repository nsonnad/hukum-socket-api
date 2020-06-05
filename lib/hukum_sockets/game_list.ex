defmodule HukumSockets.GameList do
  use GenServer

  defmodule GameListGame do
    defstruct(
      started_by: nil,
      players: 1,
      private: false,
      name: ""
    )
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]), do: {:ok, MapSet.new()}

  # client

  def add_game(game_name, game_opts) do
    GenServer.call(__MODULE__, {:add_game, game_name, game_opts})
  end

  def get_games() do
    GenServer.call(__MODULE__, :get_games)
  end

  def game_exists?(game_name) do
    GenServer.call(__MODULE__, { :game_exists?, game_name })
  end

  # server

  def handle_call({ :add_game, game_name, %{"user_name" => user_name, "private" => private}}, _from, game_list) do
    case !check_for_game?(game_list, game_name) do
      true ->
        new_list = MapSet.put(
          game_list,
          %GameListGame{
            name: game_name,
            started_by: user_name,
            private: private
          })

        { :reply, { :ok, new_list }, new_list }
      false ->
        { :reply, {:error, :name_taken }, game_list }
    end
  end

  def handle_call(:get_games, _from, game_list) do
    {:reply, game_list, game_list}
  end

  def handle_call({ :game_exists?, game_name }, _from, game_list) do
    case check_for_game?(game_list, game_name) do
      true -> {:reply, :ok, game_list}
      false -> {:reply, {:error, :game_does_not_exist}, game_list}
    end
  end

  defp check_for_game?(game_list, name) do
    Enum.any?(game_list, fn game -> game.name == name end)
  end

end
