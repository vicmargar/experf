defmodule Experf.Worker do
  defmacro __using__(_) do
    quote do
      def run(coordinator, options \\ %{verbose: false} ) do
        try do
          send(coordinator, {self(), :run_permission})

          receive do
            {:run, n} ->
              do_run(n, options)
          end
        rescue
          error ->
            :gen_server.cast(:results, {:error})
        after
          send(coordinator, {self(), :finished})
        end
      end

      defp do_run(n, options) do
        start  = :erlang.now()
        case execute(n, options) do
          :ok ->
            finish = :erlang.now()
            diff   = :timer.now_diff(finish, start)
            :gen_server.cast(:results, {:success, diff})
          :error ->
            :gen_server.cast(:results, {:error})
        end
      end

      def execute(_n, _options) do
        IO.puts "Implement me!"
      end

      defoverridable [execute: 2]
    end
  end
end
