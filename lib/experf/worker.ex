defmodule Experf.Worker do
  def run(coordinator, job) do
    coordinator <- {self(), :run_permission}

    receive do
      {:run, n} ->
        execute(n, job)
        coordinator <- {self(), :finished, n}
    end
  end

  def execute(n, job) do
    job.(n)
  end
end
