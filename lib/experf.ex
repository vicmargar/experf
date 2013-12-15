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

    {:ok, list_url} = String.to_char_list(url)

    start  = :erlang.now()
    coordinator = spawn_coordinator(concurrency, rps, num_requests)
    spawn_workers(num_requests, list_url, verbose, coordinator)

    receive do
      {:finished, total} ->
        finish = :erlang.now()
        diff   = :timer.now_diff(finish, start)

        results = :gen_server.call(:results, :results)
        mean    = DescriptiveStatistics.mean(results)
        stdev   = DescriptiveStatistics.standard_deviation(results)

        IO.puts "#{inspect total} requests finished in #{diff / 1000000} secs"
        IO.puts "Average response time #{inspect round(mean / 1000)} (ms), stdev #{inspect (stdev/1000)} (ms)"
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
    job = fn(n) ->
      {{_,_,_}, {h,m,s}} = :erlang.localtime()
      {:ok, {{200, _}, _headers, body}} = :lhttpc.request(url, 'GET', [], 5000)
      if verbose do
        IO.puts "#{inspect body}"
        IO.puts "returned 200 #{inspect n} #{inspect h}:#{inspect m}:#{inspect s}"
      end
    end

    fun = fn(_) ->
      spawn Experf.Worker, :run, [coordinator, job]
    end
    Enum.each(1..num_requests, fun)
  end
end
