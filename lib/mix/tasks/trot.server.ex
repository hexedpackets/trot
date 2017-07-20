defmodule Mix.Tasks.Trot.Server do
  use Mix.Task

  @shortdoc "Starts application and server"

  @moduledoc """
  Starts Trot application with `mix trot.server`
  ## Command line options
  This task accepts the same command-line arguments as `app.start`. For additional
  information, refer to the documentation for `Mix.Tasks.App.Start`.
  For example, to run `trot.server` without checking dependencies:
    mix trot.server --no-deps-check
  """
  def run(args) do
    Mix.Task.run "app.start", args
    no_halt()
  end

  defp no_halt do
    unless iex_running?(), do: :timer.sleep(:infinity)
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) && IEx.started?
  end
end
