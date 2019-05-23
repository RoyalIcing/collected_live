defmodule CollectedLive.Content.Text do
  use Ecto.Schema
  import Ecto.Changeset

  # @derive Phoenix.Param
  embedded_schema do
    field :content, :string
  end

  def changeset(%CollectedLive.Content.Text{} = text, params \\ %{}) do
    text
      |> cast(params, [:content])
      |> validate_required([:content])
  end
end

defimpl Phoenix.Param, for: CollectedLive.Content.Text do
  def to_param(%CollectedLive.Content.Text{id: id}) do
    Base.url_encode64(id)
  end

  def to_param(%CollectedLive.Content.Text{content: content}) when is_binary(content) do
    Base.url_encode64(:crypto.hash(:sha256, content))
  end

end
