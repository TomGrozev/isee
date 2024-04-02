defmodule IseeWeb.Nav do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_tab, :handle_params, &set_active_tab/3)}
  end

  defp set_active_tab(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {IseeWeb.MapLive, _} ->
          :map

        {IseeWeb.CamerasLive, _} ->
          :cameras

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab, headinng: nil)}
  end
end
