defmodule Experf.Coordinator do
  def start_coordination(concurrency, rps) do
    coordinate(0, 0, concurrency, 0, HashDict.new)
  end

  @doc """
  Handles :run_permission and :finished messages when max_concurrency HAS been reached.
  run_permission will only store the pid, :finished will ask a process to run
  """
  def coordinate(inserted, executed, max_concurrency, max_concurrency, pids) do
    receive do
      { pid, :run_permission } ->
        pids = HashDict.put(pids, inserted + 1, pid)
        coordinate(inserted + 1, executed, max_concurrency, max_concurrency, pids)
      { pid, :finished, x } ->
         run(executed + 1, pids)
         coordinate(inserted, executed + 1, max_concurrency, max_concurrency, pids)
    end
  end

  @doc """
  Handles :run_permission and :finished messages when max_concurrency HAS NOT been reached
  yet, in both cases a new process is asked to run
  """
  def coordinate(inserted, executed, max_concurrency, concurrency, pids) do
    receive do
      { pid, :run_permission } ->
        pids = HashDict.put(pids, inserted + 1, pid)
        run(executed + 1, pids)
        coordinate(inserted + 1, executed + 1, max_concurrency, concurrency + 1, pids)
      { pid, :finished, x } ->
        run(executed + 1, pids)
        coordinate(inserted, executed + 1, max_concurrency, concurrency + 1, pids)
    end
  end

  def run(n, pids) do
    pid = HashDict.get(pids, n)
    if pid do
      pid <- {:run, n}
    end
  end
end
