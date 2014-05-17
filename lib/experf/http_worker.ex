defmodule Experf.HttpWorker do
  use Experf.Worker

  def execute(n, options) do
    {{_,_,_}, {h,m,s}} = :erlang.localtime()

    url     = options[:url]
    verbose = options[:verbose]

    case HTTPotion.get url do
      %HTTPotion.Response{status_code: 200, body: body} ->
        if verbose do
          IO.puts "#{inspect body}"
          IO.puts "returned 200 #{inspect n} #{inspect h}:#{inspect m}:#{inspect s}"
        end
        :ok
      error ->
        IO.puts "Unexpected Response: #{inspect(error)}"
        :error
    end
  end
end
