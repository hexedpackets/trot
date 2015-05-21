defmodule Trot.Template do
  @moduledoc """
  Server side templates used to render HTML.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Trot.Template
      @before_compile Trot.Template
    end
  end

  defmacro __before_compile__(env) do
    template_root = Module.get_attribute(env.module, :template_root) || "templates"
    template_files = Trot.Template.find_all(template_root)
    templates = Trot.Template.compile(template_files, template_root)

    quote do
      @doc """
      Returns the template root alongside all template filenames.
      """
      def __templates__ do
        {unquote(template_root), unquote(template_files)}
      end

      unquote(templates)
    end
  end

  @doc """
  Finds and compiles template files.
  """
  def compile(files, root) when is_list(files) do
    files
    |> Enum.map(&(compile(&1, root)))
  end
  def compile(file, root) when is_binary(file) do
    quoted = EEx.compile_file(file)
    file_match = Path.relative_to(file, root)
    quote do
      def render_template(unquote(file_match), var!(assigns)) do
        unquote(quoted)
      end
    end
  end

  @doc """
  Finds all template files under a given root directory.
  """
  def find_all(nil), do: []
  def find_all(root) do
    Path.join(root, "**.eex")
    |> Path.wildcard
  end
end
