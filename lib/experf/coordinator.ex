require Logger

defmodule CoordinatorStatus do
  defstruct inserted: 0, # num of processes that asked for permission to run
            executed: 0, # num of processes that started running
            executed_this_second: 0, # num of processes told to run in the current second
            finished: 0, # num of processes that finished running
            concurrency: 0,
            max_concurrency: 0,
            pids: [],
            rps: 0,
            num_requests: 0
end

defmodule Experf.Coordinator do
  def start_coordination(%{concurrency: concurrency, rps: rps, num_requests: num_requests}) do
    Process.register(self, Experf.Coordinator)
    Process.send_after(self, {:second}, 1000)
    status = %CoordinatorStatus{concurrency: concurrency, pids: HashDict.new, rps: rps, num_requests: num_requests}
    coordinate(status)
    # send(caller, {:finished, num_requests})
  end

  def coordinate(%CoordinatorStatus{finished: num_requests, num_requests: num_requests}) do
    :ok
  end

  def coordinate(status = %CoordinatorStatus{concurrency: max_concurrency, max_concurrency: max_concurrency}) do
    wait_for_message(status)
  end

  def coordinate(status = %CoordinatorStatus{executed_this_second: rps, rps: rps}) do
    wait_for_message(status)
  end

  def coordinate(status = %CoordinatorStatus{inserted: inserted, executed: executed, executed_this_second: executed_this_second, concurrency: concurrency}) when inserted > executed do
    run(executed + 1, status)
    coordinate(%{status | executed: executed + 1, concurrency: concurrency + 1, executed_this_second: executed_this_second + 1})
  end

  def coordinate(status = %CoordinatorStatus{inserted: inserted, executed: inserted}) do
    wait_for_message(status)
  end

  defp wait_for_message(status) do
    receive do
      { :second } ->
        new_second(status)
      { pid, :run_permission } ->
        run_permission(pid, status)
      { _pid, :finished } ->
        finished(status)
    end
  end

  defp new_second(status) do
    Logger.info "#{inspect status.finished}/#{status.num_requests} requests finished"
    Process.send_after(self, {:second}, 1000)
    coordinate(%{status | executed_this_second: 0})
  end

  defp run_permission(pid, status = %CoordinatorStatus{inserted: inserted, pids: pids}) do
    pids = HashDict.put(pids, inserted + 1, pid)
    coordinate(%{status | inserted: inserted + 1, pids: pids})
  end

  defp finished(status = %CoordinatorStatus{concurrency: concurrency, finished: finished}) do
    coordinate(%{status | finished: finished + 1, concurrency: concurrency - 1})
  end

  defp run(n, %CoordinatorStatus{pids: pids}) do
    pid = HashDict.get(pids, n)
    if pid do
      send(pid, {:run, n})
    end
  end
end
