defmodule Experf.Supervisor do
  use Supervisor

  # A convenience to start the supervisor
  def start_link do
    Supervisor.start_link(Experf.Supervisor, [])
  end

  # The callback invoked when the supervisor starts
  def init([]) do
    children = [ worker(Experf.Results, []) ]
    supervise children, strategy: :one_for_one
  end
end
