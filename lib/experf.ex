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

    coordinator = spawn Experf.Coordinator, :start_coordination, [concurrency, rps]

    fun = fn(_) ->
      spawn Experf.Worker, :run, [coordinator]
    end
    Enum.map(1..num_requests, fun)

    receive do
      :finish -> :ok
    end
  end

  def parse_args(args) do
    {options, _, _} = OptionParser.parse(args, switches: [help: :boolean, num_requests: :integer, rps: :integer, concurrency: :integer],
                                      aliases: [h: :help, n: :num_requests, s: :rps, c: :concurrency])

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
