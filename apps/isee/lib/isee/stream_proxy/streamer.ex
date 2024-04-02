defmodule Isee.StreamProxy.Streamer do
  @moduledoc """
  Converts the input mjpeg stream to a hls stream that is proxied
  """
  use Membrane.Pipeline

  def start_link({url, stream_id}),
    do: Membrane.Pipeline.start_link(__MODULE__, {url, stream_id}, name: __MODULE__)

  @impl true
  def handle_init(_context, {uri, stream_id}) do
    src = %Membrane.Hackney.Source{location: URI.to_string(uri), hackney_opts: [follow_redirect: true]}

    sink = %Membrane.HTTPAdaptiveStream.SinkBin{
      manifest_module: Membrane.HTTPAdaptiveStream.HLS,
      target_window_duration: :infinity,
      persist?: false,
      storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: "output"}
    }

    spec = [
      child(:src, src)
      |> child(:converter, %Membrane.FFmpeg.SWScale.PixelFormatConverter{format: :I420})
      |> child(:encoder, %Membrane.H264.FFmpeg.Encoder{profile: :baseline})
      # |> via_out(:output)
      # |> child(:video_payloader, Membrane.MP4.Payloader.H264)
      |> via_in(Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(4)]
      )
      |> child(:sink, sink)
    ]

    # spec = %ChildrenSpec{
    #   children: %{
    #     src: %File.Source{location: "http://204.106.237.68:88/mjpg/1/video.mjpg"},
    #     sink: %Membrane.HTTPAdaptiveStream.SinkBin{
    #       manifest_module: Membrane.HTTPAdaptiveStream.HLS,
    #       target_window_duration: :infinity,
    #       mode: :live,
    #       persist?: false,
    #       storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: "output"}
    #     }
    #   },
    #   links: [
    #     link(:src)
    #     |> via_out(:video)
    #     |> via_in(Pad.ref(:input, :video), options: [encoding: :H264])
    #     |> to(:sink)
    #   ]
    # }

    {[spec: spec, playback: :playing], %{}}
  end
end
