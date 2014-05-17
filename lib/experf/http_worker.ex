defmodule Experf.HttpWorker do
  use Experf.Worker

  def job(n, options) do
    {{_,_,_}, {h,m,s}} = :erlang.localtime()

    url     = options[:url]
    verbose = options[:verbose]

    try do
      %HTTPotion.Response{status_code: 200, body: body} = HTTPotion.get url

      if verbose do
        IO.puts "#{inspect body}"
        IO.puts "returned 200 #{inspect n} #{inspect h}:#{inspect m}:#{inspect s}"
      end
      :ok
    rescue
      HTTPotion.HTTPError ->
        IO.puts "Error!"
        :error
    end
  end
end
