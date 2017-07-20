defmodule Trot.Template.Engine do
  @moduledoc """
  Defines the API for rendering a template format.

  Both the `compile/1` and `full_compile/1` must specified. `compile/1` is
  used to partial render a template while allowing it to be changed on disk
  without recompiling the application. `full_compile/1` is intended for
  production usage and should output the full quoted version of the template.
  """

  @doc """
  Return a quoted expression used to render a file from disk.
  """
  @callback compile(template_file :: binary) :: Macro.t

  @doc """
  Return a quoted expression of a fully rendered template which only needs to have
  variables assigned.
  """
  @callback full_compile(template_file :: binary) :: Macro.t
end
