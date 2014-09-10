require Logger

defmodule Experf.HttpWorker do
  use Experf.Worker

  def execute(n, options = %{url: url}) do
    {{_,_,_}, {h,m,s}} = :erlang.localtime()

    verbose = options[:verbose]

    case HTTPotion.get url do
      %HTTPotion.Response{status_code: 200, body: body} ->
        if verbose do
          Logger.info "#{inspect body}"
          Logger.info "returned 200 #{inspect n} #{inspect h}:#{inspect m}:#{inspect s}"
        end
        :ok
      error ->
        Logger.info "Unexpected Response: #{inspect(error)}"
        :error
    end
  end
end
