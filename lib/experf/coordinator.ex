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
    status = %CoordinatorStatus{concurrency: concurrency, rps: rps, num_requests: num_requests}
    receive do
      :start ->
        new_second(status)
    end
  end

  def coordinate(%{finished: num_requests, num_requests: num_requests}) do
    :ok
  end

  def coordinate(status = %{concurrency: max_concurrency, max_concurrency: max_concurrency}) do
    wait_for_message(status)
  end

  def coordinate(status = %{executed_this_second: rps, rps: rps}) do
    wait_for_message(status)
  end

  # Do we need to keep track of inserted? We have the list of pids so we know there are still remaining processes
  def coordinate(status = %{pids: [pid | pids],inserted: inserted, executed: executed, executed_this_second: executed_this_second, concurrency: concurrency}) when inserted > executed do
    send(pid, {:run, executed + 1})
    coordinate(%{status | executed: executed + 1, concurrency: concurrency + 1, executed_this_second: executed_this_second + 1, pids: pids})
  end

  # is this quivalent to pids: [] ????, do we need this at all????
  def coordinate(status = %{inserted: inserted, executed: inserted}) do
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

  defp run_permission(pid, status = %{inserted: inserted, pids: pids}) do
    coordinate(%{status | inserted: inserted + 1, pids: pids ++ [pid]})
  end

  defp finished(status = %{concurrency: concurrency, finished: finished}) do
    coordinate(%{status | finished: finished + 1, concurrency: concurrency - 1})
  end
end
