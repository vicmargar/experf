require Logger

defmodule Experf.Http do
  def request(id, url) do
    try do
      response = HTTPoison.get(url)
      handle_response(response, id)
    rescue
      error in HTTPoison.HTTPError ->
        Logger.info "#{id}: error (#{inspect error.message})"
    end
  end

  defp handle_response(result = %HTTPoison.Response{status_code: 200}, id) do
    Logger.info "#{id}: success"
  end

  defp handle_response(result = %HTTPoison.Response{status_code: status_code}, id) do
    Logger.info "#{id}: error (#{status_code})"
  end
end