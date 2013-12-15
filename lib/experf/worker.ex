defmodule Experf.Worker do
  def run(coordinator, job) do
    coordinator <- {self(), :run_permission}

    receive do
      {:run, n} ->
        execute(n, job)
        coordinator <- {self(), n, :finished}
    end
  end

  def execute(n, job) do
    start  = :erlang.now()
    job.(n)
    finish = :erlang.now()
    diff = :timer.now_diff(finish, start)
    :gen_server.cast(:experf, {:push, diff})
  end
end
