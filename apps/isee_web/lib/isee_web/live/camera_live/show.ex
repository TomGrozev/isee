defmodule IseeWeb.CameraLive.Show do
  use IseeWeb, :live_view

  alias Isee.Cameras
  alias Isee.ServiceLookup

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    camera = Cameras.get_camera!(id)
    ip = Cameras.get_ip(camera)

    ServiceLookup.get_ip_details(ip)
    Isee.StreamProxy.start_stream(camera.url)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:camera, camera)
     |> assign(:ip, ip)
     |> assign(:ip_details, nil)
     |> assign(:ip_details_loading, true)}
  end

  @impl true
  def handle_event("set-ip-coords", _, socket) do
    %{latitude: latitude, longitude: longitude} = socket.assigns.ip_details

    case Cameras.update_camera(socket.assigns.camera, %{
           "latitude" => latitude,
           "longitude" => longitude
         }) do
      {:ok, camera} ->
        {:noreply,
         socket
         |> assign(:camera, camera)
         |> put_flash(:info, "Coordinates set successfully")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Error setting coordinates")}
    end
  end

  @impl true
  def handle_info({:get_ip_details, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:ip_details_loading, false)
     |> put_flash(:error, "Unable to load IP details: #{reason}")}
  end

  def handle_info({:get_ip_details, {:ok, details}}, socket) do
    {:noreply,
     socket
     |> assign(:ip_details_loading, false)
     |> assign(:ip_details, details)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Camera"
  defp page_title(:edit), do: "Edit Camera"
end
