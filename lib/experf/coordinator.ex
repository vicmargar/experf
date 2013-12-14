defrecord CoordinatorStatus,
          inserted: 0,
          executed: 0,
          concurrency: 0,
          max_concurrency: 0,
          pids: [],
          start: 0,
          rps: 0,
          executed_this_second: 0,
          num_requests: 0,
          finished: 0

defmodule Experf.Coordinator do
  def start_coordination(concurrency, rps, num_requests, caller) do
    start = :erlang.now()
    status = CoordinatorStatus.new concurrency: concurrency, pids: HashDict.new, start: start, rps: rps, num_requests: num_requests
    coordinate(status)
    caller <- {:finished, num_requests}
  end

  @doc """
  num_requests have finished
  """
  # def coordinate(CoordinatorStatus[num_requests: num_requests, finished: num_requests]) do
  #   :ok
  # end

  @doc """
  Handles :run_permission and :finished messages when max_concurrency HAS been reached.
  run_permission will only store the pid, :finished will ask a process to run
  """
  def coordinate(status = CoordinatorStatus[concurrency: max_concurrency, max_concurrency: max_concurrency]) do
    inserted             = status.inserted
    executed             = status.executed
    finished             = status.finished
    pids                 = status.pids
    executed_this_second = status.executed_this_second
    rps                  = status.rps
    start                = status.start
    num_requests         = status.num_requests
    receive do
      { pid, :run_permission } ->
        pids = HashDict.put(pids, inserted + 1, pid)
        coordinate(status.inserted(inserted + 1).pids(pid))
      { pid, :finished } ->
        finished = finished + 1
        IO.puts "finished #{inspect finished}"
        unless finished == num_requests do
          {start, executed_this_second} = run(executed + 1, pids, start, rps, executed_this_second)
          coordinate(status.executed(executed + 1).finished(finished).executed_this_second(executed_this_second).start(start))
        end
    end
  end

  @doc """
  Handles :run_permission and :finished messages when max_concurrency HAS NOT been reached
  yet, in both cases a new process is asked to run
  """
  def coordinate(status = CoordinatorStatus[]) do
    concurrency          = status.concurrency
    inserted             = status.inserted
    executed             = status.executed
    finished             = status.finished
    pids                 = status.pids
    executed_this_second = status.executed_this_second
    rps                  = status.rps
    start                = status.start
    num_requests         = status.num_requests
    receive do
      { pid, :run_permission } ->
        pids = HashDict.put(pids, inserted + 1, pid)
        {start, executed_this_second} = run(executed + 1, pids, start, rps, executed_this_second)
        coordinate(status.inserted(inserted + 1).executed(executed + 1).concurrency(concurrency + 1).pids(pids).executed_this_second(executed_this_second).start(start))
      { pid, :finished } ->
        finished = finished + 1
        IO.puts "finished #{inspect finished}"
        unless finished == num_requests do
          {start, executed_this_second} = run(executed + 1, pids, start, rps, executed_this_second)
          coordinate(status.executed(executed + 1).concurrency(concurrency + 1).pids(pids).start(start).executed_this_second(executed_this_second).finished(finished))
        end
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
    IO.puts "sleeping for #{inspect sleep} us"
    # we can't sleep the coordinator, we need to somehow tell the worker to run after sleep microseconds
    # the number of executed this second has to be based on the number of finished processes.
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
