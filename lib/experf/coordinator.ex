defrecord CoordinatorStatus,
          inserted: 0, # asked for permission to run
          executed: 0, # started running
          finished: 0, # finished running
          concurrency: 0,
          max_concurrency: 0,
          pids: [],
          rps: 0,
          executed_this_second: 0,
          num_requests: 0

defmodule Experf.Coordinator do
  def start_coordination(concurrency, rps, num_requests, caller) do
    timer = :erlang.send_after(1000, self, {:second})
    status = CoordinatorStatus.new concurrency: concurrency, pids: HashDict.new, rps: rps, num_requests: num_requests
    :ok = coordinate(status)
    caller <- {:finished, num_requests}
  end

  def coordinate(status = CoordinatorStatus[finished: num_requests, num_requests: num_requests]) do
    :ok
  end

  def coordinate(status = CoordinatorStatus[concurrency: max_concurrency, max_concurrency: max_concurrency]) do
    wait_for_message(status)
  end

  def coordinate(status = CoordinatorStatus[executed_this_second: rps, rps: rps]) do
    wait_for_message(status)
  end

  def coordinate(status = CoordinatorStatus[inserted: inserted, executed: executed, executed_this_second: executed_this_second, concurrency: concurrency]) when inserted > executed do
    run(executed + 1, status)
    coordinate(status.executed(executed + 1).concurrency(concurrency + 1).executed_this_second(executed_this_second + 1))
  end

  def coordinate(status = CoordinatorStatus[inserted: inserted, executed: inserted]) do
    wait_for_message(status)
  end

  defp wait_for_message(status) do
    receive do
      { :second } ->
        new_second(status)
      { pid, :run_permission } ->
        run_permission(pid, status)
      { pid, :finished } ->
        finished(status)
    end
  end

  defp new_second(status) do
    timer = :erlang.send_after(1000, self, {:second})
    coordinate(status.executed_this_second(0))
  end

  def run_permission(pid, status = CoordinatorStatus[inserted: inserted, pids: pids]) do
    pids = HashDict.put(pids, inserted + 1, pid)
    coordinate(status.inserted(inserted + 1).pids(pids))
  end

  defp finished(status = CoordinatorStatus[concurrency: concurrency, finished: finished]) do
    coordinate(status.finished(finished + 1).concurrency(concurrency - 1))
  end

  defp run(n, status = CoordinatorStatus[pids: pids]) do
    pid = HashDict.get(pids, n)
    if pid do
      pid <- {:run, n}
    end
  end
end
