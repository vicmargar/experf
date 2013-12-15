defmodule Experf.Supervisor do
  use Supervisor.Behaviour

  # A convenience to start the supervisor
  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  # The callback invoked when the supervisor starts
  def init([]) do
    children = [ worker(Experf.Results, []) ]
    supervise children, strategy: :one_for_one
  end
end
