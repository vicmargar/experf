defmodule Experf.Coordinator do
  def start_coordination(concurrency, rps) do
    start = :erlang.now()
    coordinate(0, 0, concurrency, 0, HashDict.new, start, rps, 0)
  end

  @doc """
  Handles :run_permission and :finished messages when max_concurrency HAS been reached.
  run_permission will only store the pid, :finished will ask a process to run
  """
  def coordinate(inserted, executed, max_concurrency, max_concurrency, pids, start, rps, executed_this_second) do
    receive do
      { pid, :run_permission } ->
        pids = HashDict.put(pids, inserted + 1, pid)
        coordinate(inserted + 1, executed, max_concurrency, max_concurrency, pids, start, rps, executed_this_second)
      { pid, :finished, x } ->
        {start, executed_this_second} = run(executed + 1, pids, start, rps, executed_this_second)
        coordinate(inserted, executed + 1, max_concurrency, max_concurrency, pids, start, rps, executed_this_second)
    end
  end

  @doc """
  Handles :run_permission and :finished messages when max_concurrency HAS NOT been reached
  yet, in both cases a new process is asked to run
  """
  def coordinate(inserted, executed, max_concurrency, concurrency, pids, start, rps, executed_this_second) do
    receive do
      { pid, :run_permission } ->
        pids = HashDict.put(pids, inserted + 1, pid)
        {start, executed_this_second} = run(executed + 1, pids, start, rps, executed_this_second)
        coordinate(inserted + 1, executed + 1, max_concurrency, concurrency + 1, pids, start, rps, executed_this_second)
      { pid, :finished, x } ->
        {start, executed_this_second} = run(executed + 1, pids, start, rps, executed_this_second)
        coordinate(inserted, executed + 1, max_concurrency, concurrency + 1, pids, start, rps, executed_this_second)
    end
  end


  @doc """
  Handles run when max rps has been reached. Sleeps until the second is finished
  """
  def run(n, pids, start, rps, rps) do
    now = :erlang.now()
    diff = :timer.now_diff(now, start)
    remaining = 1000000 - diff
    sleep = max(0,remaining)
    :timer.sleep(round(sleep / 1000))
    run(n, pids, :erlang.now(), rps, 0)
  end

  @doc """
  Handles run when max rps has NOT been reached. Tells worker to run.
  """
  def run(n, pids, start, rps, executed_this_second) do
    pid = HashDict.get(pids, n)
    if pid do
      pid <- {:run, n}
    end
    {start, executed_this_second + 1}
  end
end
