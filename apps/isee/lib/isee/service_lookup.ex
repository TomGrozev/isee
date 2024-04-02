defmodule Isee.ServiceLookup do
  @moduledoc """
  GenServer for service lookups
  """

  use GenServer

  require Logger

  alias Isee.{IpApi, OsmApi}

  # Client

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Gets IP details from IP
  """
  @spec get_ip_details(String.t()) :: :ok
  def get_ip_details(ip), do: GenServer.cast(__MODULE__, {:get_ip_details, self(), ip})

  @doc """
  Searches OSM using a query
  """
  @spec search_osm(query :: String.t(), opts :: Keyword.t()) :: :ok
  def search_osm(query, opts \\ []),
    do: GenServer.cast(__MODULE__, {:search_osm, self(), {query, opts}})

  @doc """
  Gets an address from coordinates
  """
  @spec reverse_coordinates(
          lat :: ArangoXEcto.GeoData.coordinate(),
          lon :: ArangoXEcto.GeoData.coordinate(),
          opts :: Keyword.t()
        ) :: :ok
  def reverse_coordinates(lat, lon, opts \\ []),
    do: GenServer.cast(__MODULE__, {:reverse_coordinates, self(), {lat, lon, opts}})

  # Server

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:get_ip_details, sender, ip}, state) do
    key = get_ip_cache_key(ip)

    res =
      case Cachex.get(Isee.Cache, key) do
        {:ok, nil} -> fetch_and_save(key, fn -> IpApi.geo_locate_ip(ip) end)
        {:ok, val} -> {:ok, val}
        _ -> fetch_and_save(key, fn -> IpApi.geo_locate_ip(ip) end)
      end

    send(sender, {:get_ip_details, res})

    {:noreply, state}
  end

  def handle_cast({:search_osm, sender, {query, opts}}, state) do
    res = OsmApi.search(query, opts)

    send(sender, {:search_results, res})

    {:noreply, state}
  end

  def handle_cast({:reverse_coordinates, sender, {lat, lon, opts}}, state) do
    key = get_coords_cache_key(lat, lon, opts)

    res =
      case Cachex.get(Isee.Cache, key) do
        {:ok, nil} -> fetch_and_save(key, fn -> OsmApi.reverse(lat, lon, opts) end)
        {:ok, val} -> {:ok, val}
        _ -> fetch_and_save(key, fn -> OsmApi.reverse(lat, lon, opts) end)
      end

    send(sender, {:reverse_coordinates, res})

    {:noreply, state}
  end

  defp fetch_and_save(key, func), do: save_to_cache(func.(), key)

  defp get_ip_cache_key(ip), do: String.to_atom("ip_details_" <> String.replace(ip, ~r/\./, "_"))

  # TODO: Check if hashing the keyword list is ordered
  defp get_coords_cache_key(lat, lon, opts),
    do: String.to_atom("coords_reverse" <> to_string(:erlang.phash2({lat, lon, opts})))

  defp save_to_cache({:error, _reason} = res, _), do: res

  defp save_to_cache({:ok, value} = res, key) do
    Cachex.put(Isee.Cache, key, value)

    res
  end
end
