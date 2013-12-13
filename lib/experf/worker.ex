defmodule Experf.Worker do
  def run(coordinator) do
    coordinator <- {self(), :run_permission}

    receive do
      {:run, n} ->
        execute(n)
        coordinator <- {self(), :finished, n}
    end
  end

  def execute(n) do
    {{_,_,_}, {h,m,s}} = :erlang.localtime()
    IO.puts "Executing #{inspect n} #{inspect h}:#{inspect m}:#{inspect s}"
    :timer.sleep(500)
  end
end
