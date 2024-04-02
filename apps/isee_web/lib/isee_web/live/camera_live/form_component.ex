defmodule IseeWeb.CameraLive.FormComponent do
  use IseeWeb, :live_component

  alias Isee.Cameras

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage camera records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="camera-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:latitude]} type="text" label="Latitude" />
        <.input field={@form[:longitude]} type="text" label="Longitude" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Camera</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{camera: camera} = assigns, socket) do
    changeset = Cameras.change_camera(camera)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"camera" => camera_params}, socket) do
    changeset =
      socket.assigns.camera
      |> Cameras.change_camera(camera_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"camera" => camera_params}, socket) do
    save_camera(socket, socket.assigns.action, camera_params)
  end

  defp save_camera(socket, :edit, camera_params) do
    case Cameras.update_camera(socket.assigns.camera, camera_params) do
      {:ok, camera} ->
        notify_parent({:saved, camera})

        {:noreply,
         socket
         |> put_flash(:info, "Camera updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_camera(socket, :new, camera_params) do
    case Cameras.create_camera(camera_params) do
      {:ok, camera} ->
        notify_parent({:saved, camera})

        {:noreply,
         socket
         |> put_flash(:info, "Camera created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
