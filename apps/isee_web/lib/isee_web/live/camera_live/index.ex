defmodule IseeWeb.CameraLive.Index do
  use IseeWeb, :live_view

  alias Isee.Cameras
  alias Isee.Cameras.Camera

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:meta, nil)
     |> stream(:cameras, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Camera")
    |> assign(:camera, Cameras.get_camera!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Camera")
    |> assign(:camera, %Camera{})
  end

  defp apply_action(socket, :import, _params) do
    socket
  end

  defp apply_action(socket, :index, params) do
    case Cameras.paginate_cameras(params) do
      {:ok, {cameras, meta}} ->
        socket
        |> assign(:meta, meta)
        |> assign(:page_title, "Listing Cameras")
        |> assign(:camera, nil)
        |> stream(:cameras, cameras, reset: true)

      {:error, _meta} ->
        push_navigate(socket, to: ~p"/cameras")
    end
  end

  @impl true
  def handle_info({IseeWeb.CameraLive.FormComponent, {:saved, camera}}, socket) do
    {:noreply, stream_insert(socket, :cameras, camera)}
  end

  def handle_info({IseeWeb.CameraLive.BulkImport, {:saved, cameras}}, socket) do
    {:noreply, insert_multiple_cameras(socket, cameras)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    camera = Cameras.get_camera!(id)
    {:ok, _} = Cameras.delete_camera(camera)

    {:noreply, stream_delete(socket, :cameras, camera)}
  end
  
  def handle_event("update-filter", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/cameras?#{params}")}
  end

  defp insert_multiple_cameras(socket, cameras) do
    Enum.reduce(cameras, socket, fn cam, acc -> stream_insert(acc, :cameras, cam) end)
  end
end
