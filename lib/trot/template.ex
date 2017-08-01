defmodule Trot.Template do
  @moduledoc """
  Server side rendering of HTML using EEx templates. When the application is
  compiled all of templates under a given path are loaded and compiled for
  faster rendering. A `render/2` function is generated for every template under
  the module attribute `@template_root`.

  By default, `@template_root` is "priv/templates/".

  ## Example:

      defmodule PiedPiper do
        use Trot.Router
        use Trot.Template
        @template_root "priv/templates/root"

        get "/compression" do
          render("compression_results.html.eex", [weissman_score: 5.2])
        end
      end
  """

  @engines [eex: Trot.Template.EEx, haml: Trot.Template.HAML]

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Trot.Template

      @template_root Path.relative_to_cwd("priv/templates")

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
    |> Enum.map(&(compile(&1, template_engine(&1), root, Mix.env)))
  end

  @doc """
  Compiles the quoted expression used to render a template from disk.
  """
  def compile(file, module, root, :dev) do
    file
    |> module.compile
    |> _compile(file, root)
  end
  @doc """
  Compiles a template into a quoted expression in memory for faster rendering.
  """
  def compile(file, module, root, _env) do
    file
    |> module.full_compile
    |> _compile(file, root)
  end

  defp _compile(block, file, root) do
    file_match = Path.relative_to(file, root)
    quote do
      def render_template(unquote(file_match), var!(assigns)) do
        unquote(block)
      end
    end
  end

  @doc """
  Finds all template files under a given root directory.
  """
  def find_all(nil), do: []
  def find_all(root) do
    extensions = @engines |> Keyword.keys |> Enum.join(",")
    root
    |> Path.join("**.{#{extensions}}")
    |> Path.wildcard
  end

  @doc """
  Returns the hash of all template paths in the given root.
  """
  @spec hash(String.t) :: binary
  def hash(root) do
    root
    |> find_all
    |> Enum.sort
    |> :erlang.md5
  end

  @doc """
  Determine which template module to use based a template's file extension.
  """
  def template_engine(file) do
    ext = extract_extension(file)
    Keyword.get(@engines, ext)
  end

  defp extract_extension(file) do
    file
    |> Path.extname
    |> String.trim_leading(".")
    |> String.to_atom
  end
end
