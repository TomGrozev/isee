defmodule IseeWeb.CameraLive.BulkImport do
  use IseeWeb, :live_component

  alias Isee.Cameras

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Bulk Import Cameras using URLs
        <:subtitle>
          Use this form to import cameras in bulk by specifying the URLs. <br />
          Either provide a list of URLs, one per line or a JSON list (only one depth).
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="camera-import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:input]} type="textarea" label="Urls" />
        <.error :for={msg <- @form[:urls].errors}><%= translate_error(msg) %></.error>
        <:actions>
          <.button phx-disable-with="Saving...">Import Cameras</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Cameras.change_import(%{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"bulk_import" => import_params}, socket) do
    changeset =
      Cameras.change_import(import_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"bulk_import" => import_params}, socket) do
    case Cameras.bulk_import_cameras(import_params) do
      {:ok, count, cameras} ->
        notify_parent({:saved, cameras})

        {:noreply,
         socket
         |> put_flash(:info, "Imported #{count} cameras successfully")
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
