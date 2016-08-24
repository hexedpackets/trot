defmodule Trot.Template.HAML do
  @moduledoc """
  Templating engine for handling ".haml" files using Calliope.
  """

  @behaviour Trot.Template.Engine

  @doc false
  def compile(file) do
    quote do
      unquote(file)
      |> Calliope.Engine.precompile_view
      |> Calliope.Render.eval(assigns: var!(assigns))
    end
  end

  @doc false
  def full_compile(file) do
    template = Calliope.Engine.precompile_view(file)
    quote do: Calliope.Render.eval(unquote(template), assigns: var!(assigns))
  end
end
