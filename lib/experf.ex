defmodule Experf do
  use Application.Behaviour

  def start(_type, stack) do
    Experf.Supervisor.start_link(stack)
  end

  def main(args) do
    args |> parse_args |> process(HashDict.new) |> print
  end

  def parse_args(args) do
    {options, _, _} = OptionParser.parse(args, switches: [help: :boolean],
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
