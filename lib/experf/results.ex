defmodule Experf.Results do
  use GenServer.Behaviour

  def start_link do
    :gen_server.start_link({ :local, :results }, __MODULE__, %{success: [], errors: 0}, [])
  end

  def init(stack) do
    { :ok, stack }
  end

  def handle_call(:results, _from, stack) do
    { :reply, stack, %{ success: [], errors: 0 } }
  end

  def handle_cast({ :success, new }, stack = %{success: success}) do
    { :noreply, %{ stack | success: [ new | success ] } }
  end

  def handle_cast({ :error }, stack = %{errors: error}) do
    { :noreply, %{ stack | errors: error + 1 } }
  end
end
