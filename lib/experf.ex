require Logger

defmodule Experf do
  use Application

  def start(_type, []) do
    Experf.Supervisor.start_link
  end

  def main(args) do
    options = args |> parse_args |> load_file |> Enum.into(%{})
    Logger.info "#{inspect options}"

    coordinator_task = Task.async(Experf.Coordinator, :start_coordination, [options])
    spawn_workers(options, Experf.Coordinator)

    start  = :erlang.now()
    send(Experf.Coordinator, :start)
    Task.await(coordinator_task, :infinity)
    finish = :erlang.now()


    diff   = :timer.now_diff(finish, start)

    GenServer.call(Experf.Results, :results) |> print_results(diff)
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [num_requests: :integer, rps: :integer, concurrency: :integer, url: :string, verbose: :boolean, file: :string],
      aliases:  [n: :num_requests, s: :rps, c: :concurrency, u: :url, v: :verbose, f: :file]
    )
    options
  end

  defp load_file(options) do
    file = options[:file]
    if file do
      options = options ++ [urls: File.read!(file) |> String.split]
    end
    options
  end

  defp sample([]) do
    nil
  end
  defp sample(list) when is_list(list) do
    :lists.nth(:random.uniform(length(list)), list)
  end

  defp spawn_workers(options, coordinator) do
    for _ <- 1..options[:num_requests] do
      url_options = Dict.put(options, :url, sample(options[:urls]))

      spawn Experf.HttpWorker, :run, [coordinator, url_options]
    end
  end

  defp print_results(%{success: success, errors: errors}, diff) do
    Logger.info inspect(success)

    successful = length(success)
    mean       = DescriptiveStatistics.mean(success)
    stdev      = DescriptiveStatistics.standard_deviation(success)

    if successful > 0 do
      Logger.info "#{length(success)} requests finished in #{diff / 1000000} secs"
      Logger.info "Average response time #{inspect round(mean / 1000)} (ms), stdev #{inspect (stdev/1000)} (ms)"
    end

    Logger.info "#{successful} - Successful Requests"
    Logger.info "#{errors} - Errors"
  end
end
