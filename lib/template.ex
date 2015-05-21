defmodule Trot.Template do
  @moduledoc """
  Server side rendering of HTML using EEx templates. When the application is
  compiled all of templates under a given path are loaded and compiled for
  faster rendering. A `render/2` function is generated for every template under
  the module attribute `@template_root`.

  By default, `@template_root` is "templates/".

  ## Example:

      defmodule PiedPiper do
        use Trot.Router
        use Trot.Template
        @template_root "templates/root"

        get "/compression" do
          render("compression_results.html.eex", [weissman_score: 5.2])
        end
      end
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Trot.Template

      @template_root Path.relative_to_cwd("templates")

      @before_compile Trot.Template
    end
  end

  defmacro __before_compile__(env) do
    template_root = Module.get_attribute(env.module, :template_root)
    template_files = Trot.Template.find_all(template_root)
    templates = Trot.Template.compile(template_files, template_root)

    quote do
      @doc """
      Returns the template root alongside all template filenames.
      """
      def __templates__ do
        {@template_root, unquote(template_files)}
      end

      unquote(templates)

      @doc """
      Returns true whenever the list of templates changes in the filesystem.
      """
      def __template_recompile__? do
        unquote(hash(template_root)) != Trot.Template.hash(@template_root)
      end
    end
  end

  @doc """
  Finds and compiles template files.
  """
  def compile(files, root) when is_list(files) do
    files
    |> Enum.map(&(compile(&1, root, pre_compile_templates)))
  end
  def compile(file, root, _pre_compile = false) when is_binary(file) do
    file_match = Path.relative_to(file, root)
    quote do
      def render_template(unquote(file_match), assigns) do
        EEx.eval_file(unquote(file), assigns: assigns)
      end
    end
  end
  def compile(file, root, _pre_compile = true) when is_binary(file) do
    file_match = Path.relative_to(file, root)
    quoted = EEx.compile_file(file)
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

  @doc """
  Returns the hash of all template paths in the given root.
  """
  @spec hash(String.t) :: binary
  def hash(root) do
    find_all(root)
    |> Enum.sort
    |> :erlang.md5
  end

  defp pre_compile_templates do
    Application.get_env(:mix, :env) != :dev
  end
end
