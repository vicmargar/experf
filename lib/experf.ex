defmodule Experf do
  use Application.Behaviour

  def start(_type, []) do
    Experf.Supervisor.start_link
  end

  def main(args) do
    options = args |> parse_args
    IO.puts "#{inspect options}"

    num_requests = options[:num_requests]
    concurrency  = options[:concurrency]
    rps          = options[:rps]
    url          = options[:url]
    verbose      = options[:verbose]

    start  = :erlang.now()

    coordinator = spawn_coordinator(concurrency, rps, num_requests)
    spawn_workers(num_requests, url, verbose, coordinator)

    receive do
      {:finished, total} ->
        finish = :erlang.now()
        diff   = :timer.now_diff(finish, start)

        %{success: success, errors: errors} = :gen_server.call(:results, :results)
        mean       = DescriptiveStatistics.mean(success)
        stdev      = DescriptiveStatistics.standard_deviation(success)

        IO.puts "#{inspect total} requests finished in #{diff / 1000000} secs"
        IO.puts "Average response time #{inspect round(mean / 1000)} (ms), stdev #{inspect (stdev/1000)} (ms)"
        IO.puts "#{errors} Errors"
    end
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [num_requests: :integer, rps: :integer, concurrency: :integer, url: :string, verbose: :boolean],
      aliases:  [n: :num_requests, s: :rps, c: :concurrency, u: :url, v: :verbose]
    )
    options
  end

  defp spawn_coordinator(concurrency, rps, num_requests) do
    spawn Experf.Coordinator, :start_coordination, [concurrency, rps, num_requests, self()]
  end

  defp spawn_workers(num_requests, url, verbose, coordinator) do
    fun = fn(_) ->
      options = %{verbose: verbose, url: url}
      spawn Experf.HttpWorker, :run, [coordinator, options]
    end
    Enum.each(1..num_requests, fun)
  end
end
