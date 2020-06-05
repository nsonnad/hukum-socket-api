defmodule HukumSockets.GameList do
  use GenServer

  defmodule GameListGame do
    defstruct(
      started_by: nil,
      private: false,
      open: true
    )
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]), do: {:ok, Map.new()}

  # client

  def add_game(game_name, game_opts) do
    GenServer.call(__MODULE__, {:add_game, game_name, game_opts})
  end

  def join_game(game_name) do
    GenServer.call(__MODULE__, {:join_game, game_name})
  end

  def set_open(game_name, is_open) do
    GenServer.call(__MODULE__, {:toggle_open, game_name, is_open})
  end

  def get_games() do
    GenServer.call(__MODULE__, :get_games)
  end

  # server

  def handle_call({ :add_game, game_name, %{"user_name" => user_name, "private" => private}}, _from, game_list) do
    case !game_exists?(game_list, game_name) do
      true ->
        new_list = Map.put(
          game_list,
          game_name,
          %GameListGame{
            started_by: user_name,
            private: private
          }
        )
        { :reply, { :ok, new_list }, new_list }
      false ->
        { :reply, {:error, :name_taken }, game_list }
    end
  end

  def handle_call(:get_games, _from, game_list) do
    {:reply, game_list, game_list}
  end

  def handle_call({:join_game, game_name}, _from, game_list) do
    case game_exists?(game_list, game_name) do
      true -> {:reply, :ok, game_list}
      false -> {:reply, {:error, :game_does_not_exist}, game_list}
    end
  end

  def handle_call({:set_open, game_name, is_open}, _from, game_list) do
    new_list = Map.update(game_list, game_name, {}, fn game ->
      %{game | open: is_open}
    end)
    {:reply, :ok, new_list}
  end

  defp game_exists?(game_list, game_name) do
    Map.has_key?(game_list, game_name)
  end

end
