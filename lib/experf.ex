defmodule Experf do
  use Application.Behaviour

  def start(_type, stack) do
    Experf.Supervisor.start_link(stack)
  end

  def main(args) do
    options = args |> parse_args |> process(HashDict.new)
    print options

    num_requests = HashDict.get options, :num_requests
    concurrency  = HashDict.get options, :concurrency
    rps          = HashDict.get options, :rps
    url          = HashDict.get options, :url

    {:ok, list_url} = String.to_char_list(url)

    coordinator = spawn Experf.Coordinator, :start_coordination, [concurrency, rps, num_requests, self()]

    job = fn(n) ->
      {{_,_,_}, {h,m,s}} = :erlang.localtime()
      {:ok, {{200, 'OK'}, _headers, body}} = :lhttpc.request(list_url, 'GET', [], 5000)
      IO.puts "example.com returned 200 #{inspect n} #{inspect h}:#{inspect m}:#{inspect s}"
    end

    fun = fn(_) ->
      spawn Experf.Worker, :run, [coordinator, job]
    end
    Enum.map(1..num_requests, fun)

    receive do
      {:finished, total} ->
        IO.puts "#{inspect total} requests finished"
        results = :gen_server.call(:experf, :results)
        IO.puts "Times (us): #{inspect results}"
        mean = DescriptiveStatistics.mean(results)
        IO.puts "Mean #{inspect mean / 1000} (ms)"
    end
  end

  def parse_args(args) do
    {options, _, _} = OptionParser.parse(args, switches: [help: :boolean, num_requests: :integer, rps: :integer, concurrency: :integer, url: :string],
                                      aliases: [h: :help, n: :num_requests, s: :rps, c: :concurrency, u: :url])

    options
  end

  def process([], dict), do: dict

  def process([{key, value} | tail], dict) do
    dict = HashDict.put(dict, key, value)
    process(tail, dict)
  end

  def print(result) do
    IO.puts "#{inspect result}"
  end
end
