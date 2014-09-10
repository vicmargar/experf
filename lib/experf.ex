require Logger

defmodule Experf do
  use Application

  def start(_type, []) do
    Experf.Supervisor.start_link
  end

  def main(args) do
    options = args |> parse_args |> Enum.into(%{})
    Logger.info "#{inspect options}"

    start  = :erlang.now()

    coordinator_task = Task.async(Experf.Coordinator, :start_coordination, [options])

    spawn_workers(options, Experf.Coordinator)

    Task.await(coordinator_task)

    finish = :erlang.now()
    diff   = :timer.now_diff(finish, start)

    GenServer.call(Experf.Results, :results) |> print_results(diff)
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [num_requests: :integer, rps: :integer, concurrency: :integer, url: :string, verbose: :boolean],
      aliases:  [n: :num_requests, s: :rps, c: :concurrency, u: :url, v: :verbose]
    )
    options
  end

  defp spawn_workers(options, coordinator) do
    for _ <- 1..options[:num_requests] do
      spawn Experf.HttpWorker, :run, [coordinator, options]
    end
  end

  defp print_results(%{success: success, errors: errors}, diff) do
    successful = length(success)
    mean       = DescriptiveStatistics.mean(success)
    stdev      = DescriptiveStatistics.standard_deviation(success)

    if successful > 0 do
      Logger.info "#{length(success)} requests finished in #{diff / 1000000} secs"
      Logger.info "Average response time #{inspect round(mean / 1000)} (ms), stdev #{inspect (stdev/1000)} (ms)"
    end

    Logger.info "#{successful} - Successful Requests"
    Logger.info "#{errors}     - Errors"
  end
end
