defmodule Isee.Cameras.Camera do
  use ArangoXEcto.Schema
  import Ecto.Changeset

  import ArangoXEcto.GeoData, only: [is_latitude: 1, is_longitude: 1]

  @derive {
    Flop.Schema,
    filterable: [:url], sortable: [:url, :location], default_limit: 10, max_limit: 100
  }

  indexes([
    [fields: [:location], type: :geo, geoJson: true]
  ])

  schema "cameras" do
    field(:location, ArangoXEcto.Types.GeoJSON)
    field(:latitude, :float, virtual: true)
    field(:longitude, :float, virtual: true)
    field(:address, :string, virtual: true)
    field(:url, Isee.Utils.URI)

    timestamps()
  end

  @doc false
  def changeset(camera, attrs) do
    camera
    |> cast(attrs, [:url, :latitude, :longitude, :address])
    |> validate_required([:url])
    |> validate_coords()
    |> put_location()
  end

  defp validate_coords(changeset) do
    changeset
    |> validate_change(:latitude, fn
      :latitude, val when is_latitude(val) -> []
      _, _ -> [latitude: "invalid latitude coordinate"]
    end)
    |> validate_change(:longitude, fn
      :longitude, val when is_longitude(val) -> []
      _, _ -> [longitude: "invalid longitude coordinate"]
    end)
  end

  defp put_location(%Ecto.Changeset{valid?: true} = changeset) do
    lat = get_field(changeset, :latitude)
    lon = get_field(changeset, :longitude)
    address = get_field(changeset, :address)

    if not is_nil(lat) and not is_nil(lon) do
      ArangoXEcto.GeoData.point(lat, lon)
      |> maybe_put_address(address)
      |> then(&put_change(changeset, :location, &1))
    else
      changeset
    end
  end

  defp put_location(changeset), do: changeset

  defp maybe_put_address(point, nil), do: point
  defp maybe_put_address(point, address), do: Map.put(point, :properties, %{"address" => address})
end
