defmodule CollectedLive.Content.TextImport do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :url, :string
  end

  def changeset(%CollectedLive.Content.TextImport{} = text_import, params \\ %{}) do
    text_import
      |> cast(params, [:url])
      |> validate_required([:url])
  end
end
