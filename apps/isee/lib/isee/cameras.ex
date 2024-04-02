defmodule Isee.Cameras do
  @moduledoc """
  The Cameras context.
  """

  import Ecto.Query, warn: false
  alias Isee.Repo

  alias Isee.Cameras.{BulkImport, Camera}
  alias Isee.Utils.Helpers
  alias Isee.OsmApi

  @ip_regex ~r/((^\s*((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))\s*$)|(^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$))/

  @doc """
  Returns the list of cameras.

  ## Examples

      iex> list_cameras()
      [%Camera{}, ...]

  """
  def list_cameras do
    Repo.all(Camera)
  end

  def paginate_cameras(params) do
    try do
      Flop.validate_and_run(Camera, params, for: Camera)
    rescue 
      Ecto.NoResultsError -> 
        {:ok, {[], %Flop.Meta{current_page: 1, total_pages: 1}}}
    end
  end

  @doc """
  Returns the list of cameras with a location set.

  ## Examples

      iex> list_cameras_with_location()
      [%Camera{}, ...]

  """
  def list_cameras_with_location do
    Repo.all(from c in Camera, where: not is_nil(c.location))
  end

  @doc """
  Lists cameras within range
  """
  def list_cameras_in_range(coords, range \\ 3000)

  def list_cameras_in_range(%Geo.Point{coordinates: {lon, lat}}, range),
    do: list_cameras_in_range({lat, lon}, range)

  def list_cameras_in_range({lat, lon}, range) do
    Repo.all(
      from c in Camera,
        where:
          fragment(
            "GEO_DISTANCE(GEO_POINT(?, ?), ?)",
            ^String.to_float(lon),
            ^String.to_float(lat),
            c.location
          ) <= ^range
    )
  end

  @doc """
  Gets a single camera.

  Raises `Ecto.NoResultsError` if the Camera does not exist.

  ## Examples

      iex> get_camera!(123)
      %Camera{}

      iex> get_camera!(456)
      ** (Ecto.NoResultsError)

  """
  def get_camera!(id), do: Repo.get!(Camera, id) |> populate_coords()

  defp populate_coords(%Camera{location: %Geo.Point{coordinates: {lon, lat}}} = camera),
    do: Map.merge(camera, %{latitude: lat, longitude: lon})

  defp populate_coords(camera), do: camera

  @doc """
  Gets IP of a camera
  """
  @spec get_ip(Camera.t()) :: String.t()
  def get_ip(%Camera{url: %URI{host: host}}) do
    if String.match?(host, @ip_regex) do
      host
    else
      ip_from_host(host)
    end
  end

  defp ip_from_host(host) do
    case Helpers.hostname_to_ip(host) do
      {:ok, ip} -> ip
      {:error, _} -> "unknown"
    end
  end

  @doc """
  Creates a camera.

  ## Examples

      iex> create_camera(%{field: value})
      {:ok, %Camera{}}

      iex> create_camera(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_camera(attrs \\ %{}) do
    attrs = add_address(attrs)

    %Camera{}
    |> Camera.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a camera.

  ## Examples

      iex> update_camera(camera, %{field: new_value})
      {:ok, %Camera{}}

      iex> update_camera(camera, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_camera(%Camera{} = camera, attrs) do
    attrs = add_address(attrs)

    camera
    |> Camera.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a camera.

  ## Examples

      iex> delete_camera(camera)
      {:ok, %Camera{}}

      iex> delete_camera(camera)
      {:error, %Ecto.Changeset{}}

  """
  def delete_camera(%Camera{} = camera) do
    Repo.delete(camera)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking camera changes.

  ## Examples

      iex> change_camera(camera)
      %Ecto.Changeset{data: %Camera{}}

  """
  def change_camera(%Camera{} = camera, attrs \\ %{}) do
    Camera.changeset(camera, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking the bulk import.

  ## Examples

      iex> change_import(attrs)
      %Ecto.Changeset{data: %BulkImport{}}

  """
  def change_import(attrs) do
    BulkImport.changeset(attrs)
  end

  @doc """
  Bulk imports multiple URLs
  """
  def bulk_import_cameras(attrs) do
    with changeset <- change_import(attrs),
         {:ok, %BulkImport{urls: urls}} <- Ecto.Changeset.apply_action(changeset, :insert) do
      Enum.map(urls, &%{url: &1})
      |> then(&Repo.insert_all(Camera, &1, returning: true))
      |> then(fn {count, cameras} -> {:ok, count, cameras} end)
    end
  end

  defp add_address(%{"latitude" => lat, "longitude" => lon} = attrs) do
    case OsmApi.reverse(lat, lon, format: :jsonv2) do
      {:ok, %{"display_name" => name}} -> Map.put(attrs, "address", name)
      _ -> attrs
    end
  end

  defp add_address(attrs), do: attrs
end
