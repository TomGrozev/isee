defmodule Isee.OsmApi do
  @moduledoc """
  Functions to query the OSM API
  """

  require Logger

  import ArangoXEcto.GeoData, only: [is_latitude: 1, is_longitude: 1]

  @base_url "https://nominatim.openstreetmap.org/"

  @doc """
  Searches for an object by a query string

  Details for the available options can be found at [Nominatim docs](https://nominatim.org/release-docs/develop/api/Search/).
  """
  @spec search(query :: String.t(), opts :: Keyword.t()) :: {:ok, [map()]} | {:error, any()}
  def search(query, opts \\ []) do
    case validate_options(:search, opts) do
      {:error, errors} ->
        {:error, "the following fields are invalid: #{inspect(errors)}"}

      {:ok, opts} ->
        Logger.info(
          "[External request] Requesting query from OSM with strinng: #{inspect(query)}"
        )

        opts
        |> Keyword.put(:q, query)
        |> generate_url(:search)
        |> fetch()
        |> parse(Keyword.get(opts, :format))
    end
  end

  @doc """
  Gets an address from a latitude and longitude

  Details for the available options can be found at [Nominatim docs](https://nominatim.org/release-docs/develop/api/Reverse/).
  """
  @spec reverse(
          latitude :: ArangoXEcto.GeoData.coordinate(),
          longitude :: ArangoXEcto.GeoData.coordinate(),
          opts :: Keyword.t()
        ) ::
          {:ok, [map()]} | {:error, any()}
  def reverse(latitude, longitude, opts \\ []) do
    case validate_options(:reverse, opts) do
      {:error, errors} ->
        {:error, "the following fields are invalid: #{inspect(errors)}"}

      {:ok, opts} ->
        Logger.info(
          "[External request] Requesting reverse search from OSM with coords: #{inspect(latitude)} N, #{inspect(longitude)} E"
        )

        opts
        |> Keyword.put(:lat, latitude)
        |> Keyword.put(:lon, longitude)
        |> generate_url(:reverse)
        |> fetch()
        |> parse(Keyword.get(opts, :format))
    end
  end

  ###########
  # Helpers #
  ###########

  defp fetch(url) do
    Finch.build(:get, url)
    |> Finch.request(Isee.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Logger.debug(
          "[External request] Received response from OSM Api for query: #{inspect(url)}"
        )

        {:ok, body}

      {:ok, %Finch.Response{body: body}} ->
        Logger.error("[External request] Failed fetching from OSM Api for query: #{inspect(url)}")

        {:error, body}

      {:error, %{reason: reason}} ->
        Logger.error(
          "[External request] Failed fetching from OSM Api for query: #{inspect(url)}, with reason: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp parse({:ok, res}, format) when format in [:json, :jsonv2],
    do: {:ok, Jason.decode!(res)}

  defp parse(res, _), do: res

  defp validate_options(type, opts) do
    opts = Keyword.take(opts, valid_options_for_type(type))

    Enum.reduce(opts, [], fn {k, v}, acc -> if validate_option(k, v), do: acc, else: [k | acc] end)
    |> case do
      [] -> {:ok, opts}
      errors -> {:error, errors}
    end
  end

  defp valid_options_for_type(:search) do
    [
      :format,
      :addressdetails,
      :extratags,
      :namedetails,
      :viewbox,
      :bounded,
      :exclude_place_ids,
      :limit,
      :accept_language,
      :email
    ]
  end

  defp valid_options_for_type(:reverse) do
    [
      :format,
      :zoom,
      :addressdetails,
      :extratags,
      :namedetails,
      :accept_language,
      :email
    ]
  end

  defp generate_url(args, type) do
    args
    |> Enum.map(fn {k, v} -> "#{modify_key(k)}=#{modify_value(v)}" end)
    |> Enum.join("&")
    |> then(&"#{@base_url}#{type}?#{&1}")
  end

  defp modify_key(:accept_language), do: "accept-language"
  defp modify_key(k), do: k

  defp modify_value(true), do: "1"
  defp modify_value(false), do: "0"
  defp modify_value(val), do: URI.encode_www_form("#{val}")

  defp validate_option(:format, value),
    do: value in [:xml, :json, :jsonv2, :geojson, :geocodejson]

  defp validate_option(:addressdetails, value), do: is_boolean(value)
  defp validate_option(:extratags, value), do: is_boolean(value)
  defp validate_option(:namedetails, value), do: is_boolean(value)
  defp validate_option(:limit, value), do: is_integer(value) and value >= 1 and value <= 50
  defp validate_option(:zoom, value), do: is_integer(value) and value >= 0 and value <= 18

  defp validate_option(:viewbox, [x1, y1, x2, y2]),
    do: is_longitude(x1) and is_longitude(x2) and is_latitude(y1) and is_latitude(y2)

  defp validate_option(:bounded, value), do: is_boolean(value)
  defp validate_option(:email, value), do: is_binary(value)
  defp validate_option(:accept_language, value), do: is_binary(value)

  defp validate_option(:exclude_place_ids, value),
    do: is_list(value) and Enum.all?(value, &is_binary/1)

  defp validate_option(_, _), do: false

  # TODO: Check if hashing the keyword list is ordered
  defp get_cache_key(lat, lon, opts),
    do: String.to_atom("coords_reverse_" <> to_string(:erlang.phash2({lat, lon, opts})))

  defp save_to_cache({:error, _reason} = res, _), do: res

  defp save_to_cache({:ok, value} = res, key) do
    Cachex.put(Isee.Cache, key, value)

    res
  end
end
