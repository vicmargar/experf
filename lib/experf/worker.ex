defmodule Experf.Worker do
  defmacro __using__(_) do
    quote do
      def a do
        IO.puts "a!!!!"
      end

      def run(coordinator, job) do
        send(coordinator, {self(), :run_permission})

        receive do
          {:run, n} ->
            execute(n, job)
            send(coordinator, {self(), n, :finished})
        end
      end

      def execute(n, job) do
        start  = :erlang.now()
        job.(n)
        finish = :erlang.now()
        diff = :timer.now_diff(finish, start)
        :gen_server.cast(:results, {:push, diff})
      end
    end
  end
end
