defmodule Mix.Tasks.Trot.Server do
  use Mix.Task

  def run(args) do
    Mix.Task.run "app.start", args
    no_halt
  end

  defp no_halt do
    :timer.sleep(:infinity)
  end
end
