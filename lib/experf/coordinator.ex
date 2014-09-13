defmodule Experf.Coordinator do
  def start(n) do
    Process.register(self, Experf.Coordinator)
    coordinate(%{finished: 0, num_requests: n})
  end

  defp coordinate(%{finished: n, num_requests: n}) do
    :ok
  end

  defp coordinate(status = %{finished: f, num_requests: n}) do
    receive do
      {:finished, _i} ->
        coordinate(%{status | finished: f + 1})
    end
  end
end
