defmodule Echo.Acceptor do
  use GenServer

  require Logger

  defstruct [:listen_socket]

  def start_link(start_args) do
    GenServer.start_link(__MODULE__, start_args, name: __MODULE__)
  end

  def init(init_args) do
    port = Keyword.fetch!(init_args, :port)

    listen_options = [
      :binary,
      active: :once,
      # Do not link socket to process that creates it
      exit_on_close: false,
      # Run and shutdown server without worrying about unavailable ports
      reuseaddr: true,
      # Accept queue size
      backlog: 25
    ]

    case :gen_tcp.listen(port, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Started TCP server on port #{port}")
        send(self(), :accept)
        {:ok, %__MODULE__{listen_socket: listen_socket}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_info(:accept, state) do
    case :gen_tcp.accept(state.listen_socket, 2_000) do
      {:ok, client_socket} ->
        {:ok, pid} = Echo.Connection.start_link(client_socket)
        :ok = :gen_tcp.controlling_process(client_socket, pid)
        send(self(), :accept)
        {:noreply, state}

      {:error, :timeout} ->
        send(self(), :accept)
        {:noreply, state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end
end
