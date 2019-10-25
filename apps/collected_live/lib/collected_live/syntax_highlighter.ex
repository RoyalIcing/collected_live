defmodule CollectedLive.SyntaxHighlighter do
  defmodule Engine do
    use Rustler, otp_app: :collected_live, crate: :collectedlive_syntaxhighlighter

    def highlight_html(_input, _extension), do: :erlang.nif_error(:nif_not_loaded)
  end

  def highlight(:html, input) do
    {:ok, html} = Engine.highlight_html(input, to_string(:html))
    Phoenix.HTML.raw(html)
  end

  def highlight(:js, input) do
    {:ok, html} = Engine.highlight_html(input, to_string(:js))
    Phoenix.HTML.raw(html)
  end

  def highlight(extension, input) when is_atom(extension) do
    {:ok, html} = Engine.highlight_html(input, to_string(extension))
    Phoenix.HTML.raw(html)
  end

  def highlight(extension, input) when is_binary(extension) do
    {:ok, html} = Engine.highlight_html(input, extension)
    Phoenix.HTML.raw(html)
  end
end
