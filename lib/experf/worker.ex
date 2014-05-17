defmodule Experf.Worker do
  defmacro __using__(_) do
    quote do
      def a do
        IO.puts "a!!!!"
      end

      def run(coordinator, options \\ %{verbose: false} ) do
        send(coordinator, {self(), :run_permission})

        receive do
          {:run, n} ->
            execute(n, options)
            send(coordinator, {self(), n, :finished})
        end
      end

      def execute(n, options) do
        start  = :erlang.now()
        case job(n, options) do
          :ok ->
            finish = :erlang.now()
            diff = :timer.now_diff(finish, start)
            :gen_server.cast(:results, {:success, diff})
          :error ->
            :gen_server.cast(:results, {:error})
        end
      end

      def job(_n, _options) do
        IO.puts "Implement me!"
      end

      defoverridable [job: 2]
    end
  end
end
