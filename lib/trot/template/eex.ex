defmodule Trot.Template.EEx do
  @moduledoc """
  Templating engine for handling ".eex" files.
  """

  @behaviour Trot.Template.Engine

  @doc false
  def compile(file) do
    quote do: EEx.eval_file(unquote(file), assigns: var!(assigns))
  end

  @doc false
  def full_compile(file) do
    EEx.compile_file(file)
  end
end
