defmodule Trot.Template.Slim do
  @moduledoc """
  Templating engine for handling ".slim" files using Calliope.
  """

  @behaviour Trot.Template.Engine

  @doc false
  def compile(file) do
    quote do
      unquote(file)
      |> File.read!
      |> Slime.Renderer.render(assigns: var!(assigns))
    end
  end

  @doc false
  def full_compile(file) do
    file
    |> File.read!
    |> Slime.Renderer.precompile
    |> EEx.compile_string
  end
end
