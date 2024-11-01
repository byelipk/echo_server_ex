defmodule EchoTest do
  use ExUnit.Case

  describe "server" do
    test "sends back the received data" do
      {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])

      assert :ok = :gen_tcp.send(socket, "hello\n")

      assert {:ok, data} = :gen_tcp.recv(socket, 0, 500)
      assert "hello\n" == data
    end

    test "handles fragmented data" do
      {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])

      assert :ok = :gen_tcp.send(socket, "hello")
      assert :ok = :gen_tcp.send(socket, " world\nand one more line\n")

      assert {:ok, data} = :gen_tcp.recv(socket, 0, 500)
      assert "hello world\nand one more line\n" == data
    end

    test "handles multiple clients simultaneously" do
      tasks = for _ <- 1..5 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])

          assert :ok = :gen_tcp.send(socket, "Hello world\n")

          assert {:ok, data} = :gen_tcp.recv(socket, 0, 500)

          assert data == "Hello world\n"
        end)
      end

      Task.await_many(tasks)
    end
  end
end
