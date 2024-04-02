defmodule Isee.StreamProxy do
  @moduledoc """
  Starts stream proxy services
  """
  use GenServer

  ##########
  # Client #
  ##########

  @doc """
  Starts the proxy servie
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Starts a stream proxy for the specified URL
  """
  @spec start_stream(url :: URI.t()) :: {:ok, pid()} | {:error, any()}
  def start_stream(url) do
    GenServer.call(__MODULE__, {:start, url})
  end

  ##########
  # Server #
  ##########

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:start, uri}, _from, state) do
    stream_id = unique_string()
    start_streamer(uri, stream_id)

    {:reply, {:ok, stream_id}, Map.put(state, uri, stream_id)}
  end

  defp start_streamer(url, stream_id) do
    DynamicSupervisor.start_child(
      Isee.StreamSupervisor,
      {Isee.StreamProxy.Streamer, {url, stream_id}}
    )
  end

  defp unique_string,
    do: :crypto.strong_rand_bytes(64) |> Base.url_encode64() |> binary_part(0, 64)
end
