defmodule Isee.Cameras.BulkImport do
  @moduledoc """
  Changesets for bulk importing cameras
  """
  alias Isee.Utils.URI

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:input, :string)
    field(:urls, {:array, URI})
  end

  @doc false
  def changeset(attrs) do
    attrs = convert_urls(attrs)

    %__MODULE__{}
    |> cast(attrs, [:urls], message: fn _, _ -> "one or more URLs are invalid" end)
    |> validate_required([:urls])
  end

  defp convert_urls(%{"input" => input}) do
    case Jason.decode(input) do
      {:ok, urls} when is_list(urls) -> urls
      {:error, _} -> String.split(input, "\n", trim: true)
    end
    |> then(&%{urls: &1})
  end

  defp convert_urls(attrs), do: attrs
end
