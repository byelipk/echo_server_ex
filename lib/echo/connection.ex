defmodule Echo.Connection do
  use GenServer

  require Logger

  defstruct socket: nil, buffer: <<>>

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @impl true
  def init(socket) do
    {:ok, %__MODULE__{socket: socket}}
  end

  @impl true
  def handle_info(message, state)

  def handle_info({:tcp, socket, data}, state) do
    Logger.info("Received data: #{inspect(data)}")

    :ok = :inet.setopts(socket, active: :once)

    state = update_in(state.buffer, &(&1 <> data))
    state = handle_new_data(state)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("Connection closed")

    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("Connection closed due to error: #{inspect(reason)}")

    {:stop, reason, state}
  end

  defp handle_new_data(state) do
    case String.split(state.buffer, "\n", parts: 2) do
      [line, rest] ->
        Logger.info("Echoing line: #{inspect(line)}")

        # Echo the line back to the client
        :ok = :gen_tcp.send(state.socket, line <> "\n")

        # Store the rest of the buffer we haven't echoed yet
        state = put_in(state.buffer, rest)

        # Recursively handle any more lines in the buffer
        handle_new_data(state)

      _other ->
        state
    end
  end
end
