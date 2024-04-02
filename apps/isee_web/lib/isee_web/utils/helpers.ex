defmodule IseeWeb.Utils.Helpers do
  @moduledoc """
  Helpers for displaying web content
  """

  @doc """
  Displays coordinates in N/E form from a `Geo.Point`
  """
  @spec display_coords(Geo.Point.t()) :: String.t()
  def display_coords(%Geo.Point{coordinates: {lon, lat}}), do: display_coords(lat, lon)
  def display_coords(_), do: ""

  @doc """
  Same as `display_coords/1` but takes the coords seperately
  """
  @spec display_coords(latitude :: String.t() | float(), longitude :: String.t() | float()) ::
          String.t()
  def display_coords(lat, lon), do: "#{lat} N, #{lon} E"
end
