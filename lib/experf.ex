require Logger

defmodule Experf do
  use Application

  def start(_type, []) do
    Experf.Supervisor.start_link
  end

  def main(args) do
    options = args |> parse_args
    Logger.info "#{inspect options}"

    num_requests = options[:num_requests]
    concurrency  = options[:concurrency]
    rps          = options[:rps]
    url          = options[:url]
    verbose      = options[:verbose]

    start  = :erlang.now()

    coordinator_task = Task.async(Experf.Coordinator, :start_coordination, [concurrency, rps, num_requests])

    spawn_workers(num_requests, url, verbose, Experf.Coordinator)

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

  defp spawn_workers(num_requests, url, verbose, coordinator) do
    options = %{verbose: verbose, url: url}

    fun = fn(_) ->
      spawn Experf.HttpWorker, :run, [coordinator, options]
    end
    Enum.each(1..num_requests, fun)
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
