defmodule CollectedLiveWeb.TextController do
  use CollectedLiveWeb, :controller

  alias CollectedLive.Content
  alias CollectedLive.Content.Text

  def index(conn, _params) do
    content = Content.list_content()
    render(conn, "index.html", content: content)
  end

  def new(conn, _params) do
    changeset = Content.change_text(%Text{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"text" => text_params}) do
    case Content.create_text(text_params) do
      {:ok, text} ->
        conn
        |> put_flash(:info, "Text created successfully.")
        |> redirect(to: Routes.text_path(conn, :show, text))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    text = Content.get_text!(id)
    render(conn, "show.html", text: text)
  end

  def show_text_plain(conn, %{"text_id" => id}) do
    text = Content.get_text!(id)
    text(conn, text.content)
  end

  def edit(conn, %{"id" => id}) do
    text = Content.get_text!(id)
    changeset = Content.change_text(text)
    render(conn, "edit.html", text: text, changeset: changeset)
  end

  def update(conn, %{"id" => id, "text" => text_params}) do
    text = Content.get_text!(id)

    case Content.update_text(text, text_params) do
      {:ok, text} ->
        conn
        |> put_flash(:info, "Text updated successfully.")
        |> redirect(to: Routes.text_path(conn, :show, text))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", text: text, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    text = Content.get_text!(id)
    {:ok, _text} = Content.delete_text(text)

    conn
    |> put_flash(:info, "Text deleted successfully.")
    |> redirect(to: Routes.text_path(conn, :index))
  end
end
