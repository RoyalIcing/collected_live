defmodule CollectedLive.Content do
  alias CollectedLive.Content.Text

  def list_content do
    []
  end

  def change_text(%Text{} = text) do
    Text.changeset(text)
  end

  def create_text(params) do
    with {:ok, text} <- %Text{}
      |> Text.changeset(params)
      |> Ecto.Changeset.apply_action(:insert)
    do
      {:ok, %Text{text | id: :crypto.hash(:sha256, text.content)}}
    end
  end

  def get_text!(id_encoded) do
    case Base.url_decode64(id_encoded) do
      {:ok, id} ->
        %Text{id: id}

      :error ->
        raise Ecto.NoResultsError
    end
  end

  def delete_text(%Text{} = text) do

  end
end
