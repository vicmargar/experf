defmodule Experf.Results do
  use GenServer.Behaviour

  def start_link do
    :gen_server.start_link({ :local, :results }, __MODULE__, [], [])
  end

  def init(stack) do
    { :ok, stack }
  end

  def handle_call(:results, _from, stack) do
    { :reply, stack, [] }
  end

  def handle_cast({ :push, new }, stack) do
    { :noreply, [new|stack] }
  end
end
