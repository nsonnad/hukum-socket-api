defmodule HukumSockets.GameList do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]), do: {:ok, MapSet.new()}

  # client

  def add_game(name) do
    GenServer.call(__MODULE__, {:add_game, name})
  end

  def get_games() do
    GenServer.call(__MODULE__, :get_games)
  end

  def game_exists?(name) do
    GenServer.call(__MODULE__, { :game_exists?, name })
  end

  # server

  def handle_call({ :add_game, name }, _from, game_list) do
    case !MapSet.member?(game_list, name) do
      true -> { :reply, :ok, MapSet.put(game_list, name) }
      false -> { :reply, {:error, :name_taken }, game_list }
    end
  end

  def handle_call(:get_games, _from, game_list) do
    {:reply, game_list, game_list}
  end

  def handle_call({ :game_exists?, name }, _from, game_list) do
    case MapSet.member?(game_list, name) do
      true -> {:reply, :ok, game_list}
      false -> {:reply, {:error, :game_does_not_exist}, game_list}
    end
  end

end
