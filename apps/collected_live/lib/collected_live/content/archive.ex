defmodule CollectedLive.Content.Archive do
  defmodule Input do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:url, :string)
    end

    def changeset(%__MODULE__{} = archive, params \\ %{}) do
      archive
      |> cast(params, [:url])
      |> validate_required([:url])
    end
  end

  defmodule Item do
    defstruct name: ""

    def from_zip_file(
          {:zip_file, name,
           {:file_info, _size, _type, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _, _,
            _}, _comment, _offset, _comp_size}
        ) do
      %__MODULE__{name: name}
    end
  end

  defmodule Zip do
    defstruct zip_data: nil

    alias CollectedLive.Content.Archive.Item

    def from_data(data) when is_binary(data) do
      %__MODULE__{zip_data: data}
    end

    def zip_files(%__MODULE__{zip_data: data}) do
      case :zip.list_dir(data) do
        {:ok, [_comment | zip_files]} -> zip_files
        _ -> nil
      end
    end

    def zip_files(zip = %__MODULE__{zip_data: data}) do
      Enum.map(zip_files(zip), &Item.from_zip_file/1)
    end

    defp include_name?(name, name_containing)
         when is_binary(name) and is_binary(name_containing) do
      if String.length(name_containing) > 2 do
        String.contains?(to_string(name), name_containing)
      else
        true
      end
    end

    defp include_zip_file?(
           {:zip_file, name,
            {:file_info, _size, :regular, _access, _atime, _mtime, _ctime, _mode, _links, _, _, _,
             _, _}, _comment, _offset, _comp_size},
           name_containing
         )
         when is_binary(name_containing) do
      include_name?(to_string(name), name_containing)
    end

    defp include_zip_file?(
           {:zip_file, _, {:file_info, _, _, _, _, _, _, _, _, _, _, _, _, _}, _, _, _},
           name_containing
         )
         when is_binary(name_containing) do
      false
    end

    def filtered_zip_files(zip = %__MODULE__{}, %{
          name_containing: name_containing,
          content_containing: content_containing
        }) do
      case String.trim(content_containing) do
        "" ->
          zip_files = zip_files(zip)
          Enum.filter(zip_files, fn file -> include_zip_file?(file, name_containing) end)

        content_containing ->
          result =
            :zip.foldl(
              fn
                name_chars, get_info, get_binary, acc ->
                  with true <- include_name?(to_string(name_chars), name_containing),
                       true <- String.contains?(get_binary.(), content_containing)
                       do
                    file_info = get_info.()
                    fake_zip_file = {:zip_file, name_chars, file_info, "", 0, 0}
                    [fake_zip_file | acc]
                  else
                    _ -> acc
                  end
              end,
              [],
              {'name.zip', zip.zip_data}
            )

          case result do
            {:ok, files} -> files
            _ -> nil
          end
      end
    end

    def info_for_file_named(%__MODULE__{zip_data: data}, filename) do
      filename_chars = to_charlist(filename)

      result =
        :zip.foldl(
          fn
            ^filename_chars, get_info, _get_binary, _acc -> get_info.()
            _, _, _, acc -> acc
          end,
          nil,
          {'name.zip', data}
        )

      case result do
        {:ok, info} -> info
        _ -> nil
      end
    end

    def content_for_file_named(%__MODULE__{zip_data: data}, filename) do
      filename_chars = to_charlist(filename)

      result =
        :zip.foldl(
          fn
            ^filename_chars, _get_info, get_binary, _acc -> get_binary.()
            _, _, _, acc -> acc
          end,
          nil,
          {'name.zip', data}
        )

      case result do
        {:ok, content_data} -> content_data
        _ -> nil
      end
    end
  end
end
