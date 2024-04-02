defmodule IseeWeb.MapLive do
  use IseeWeb, :live_view

  alias Isee.Cameras
  alias Isee.ServiceLookup

  @coord_pattern ~r/^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$/

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_settings(%{"radius" => "500"})
     |> set_default(), layout: {IseeWeb.Layouts, :app_full}}
  end

  @impl true
  def handle_event("search", %{"value" => ""}, socket) do
    {:noreply, assign(socket, search_results: [], show_results: false)}
  end

  def handle_event("search", %{"value" => search_query}, socket) do
    search_query
    |> String.trim()
    |> ServiceLookup.search_osm(format: :jsonv2)

    {:noreply, assign(socket, :query, search_query)}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, set_default(socket)}
  end

  def handle_event("show-results", _params, socket) do
    if Enum.empty?(socket.assigns.search_results) do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :show_results, true)}
    end
  end

  def handle_event("hide-results", _params, socket) do
    {:noreply, assign(socket, :show_results, false)}
  end

  def handle_event(
        "search-result",
        %{"text" => text, "latitude" => lat, "longitude" => lon},
        socket
      ) do
    marker = %{text: text, latitude: lat, longitude: lon}

    {:noreply, search(socket, marker)}
  end

  def handle_event("set-search-settings", params, socket) do
    {:noreply,
     socket
     |> assign_settings(params)
     |> search(socket.assigns.marker)}
  end

  @impl true
  def handle_info({_, {:error, reason}}, socket) do
    {:noreply, put_flash(socket, :error, "Error searching: #{inspect(reason)}")}
  end

  def handle_info({:search_results, {:ok, res}}, socket) do
    results =
      Enum.map(res, fn item ->
        %{
          text: item["display_name"],
          icon_url: item["icon"],
          latitude: item["lat"],
          longitude: item["lon"]
        }
      end)

    {:noreply, assign(socket, search_results: results, show_results: not Enum.empty?(results))}
  end

  defp get_camera_name(%{location: %{properties: %{"address" => address}}}), do: address
  defp get_camera_name(%{id: id}), do: "Camera ##{id}"

  defp valid_radius?(radius), do: is_integer(radius) and radius > 0 and radius <= 2_0000

  defp search(socket, %{latitude: lat, longitude: lon} = marker) do
    settings = socket.assigns.settings
    radius = Phoenix.HTML.Form.input_value(settings, "radius") |> String.to_integer()

    if valid_radius?(radius) do
      cameras = Cameras.list_cameras_in_range({lat, lon}, radius)

      assign(socket, marker: marker, show_results: false, cameras: cameras)
    else
      socket
      |> put_flash(:error, "Falied to get search results, invalid config")
      |> assign(:show_results, false)
    end
  end

  defp search(socket, _), do: socket

  defp set_default(socket) do
    assign(socket,
      query: "",
      search_results: [],
      show_results: false,
      marker: nil,
      cameras: Cameras.list_cameras_with_location()
    )
  end

  defp assign_settings(socket, settings) do
    settings
    |> Map.take(["radius"])
    |> then(&assign(socket, :settings, to_form(&1)))
  end
end
