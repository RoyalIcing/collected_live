defmodule CollectedLive.Content.Archive do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :url, :string
  end

  def changeset(%__MODULE__{} = archive, params \\ %{}) do
    archive
      |> cast(params, [:url])
      |> validate_required([:url])
  end
end
