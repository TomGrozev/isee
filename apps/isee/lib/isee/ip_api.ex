defmodule Isee.IpApi do
  @moduledoc """
  API functions for fetching details about na IP address
  """

  require Logger

  @doc """
  Gets the geo location of an IP address
  """
  @spec geo_locate_ip(ip :: String.t()) :: {:ok, map()} | {:error, any()}
  def geo_locate_ip(ip) do
    Logger.info("[External request] Requesting geo IP details for ip: #{inspect(ip)}")

    Finch.build(:get, "https://get.geojs.io/v1/ip/geo.json?ip=#{ip}")
    |> Finch.request(Isee.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Logger.debug(
          "[External request] Received response for geo IP details for ip: #{inspect(ip)}"
        )

        body
        |> decode_geo_requet()
        |> parse_result()

      {:error, reason} ->
        Logger.error("[External Request] Failed fetching IP details: #{inspect(reason)}")
        {:error, "error fetching IP details"}
    end
  end

  defp parse_result({:error, reason}), do: {:error, reason}

  defp parse_result({:ok, details}) do
    {:ok,
     %{
       accuracy: details["accuracy"],
       city: details["city"],
       country: details["country"],
       ip: details["ip"],
       latitude: details["latitude"],
       longitude: details["longitude"],
       organisation: details["organization_name"],
       state: details["region"],
       timezone: details["timezone"]
     }}
  end

  defp decode_geo_requet(body) do
    case Jason.decode(body) do
      {:ok, [res]} ->
        {:ok, res}

      _ ->
        {:error, "error decoding IP details"}
    end
  end
end
