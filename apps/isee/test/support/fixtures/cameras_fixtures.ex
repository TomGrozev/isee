defmodule Isee.CamerasFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Isee.Cameras` context.
  """

  @doc """
  Generate a camera.
  """
  def camera_fixture(attrs \\ %{}) do
    {:ok, camera} =
      attrs
      |> Enum.into(%{
        latitude: "some latitude",
        longitude: "some longitude",
        name: "some name",
        url: "some url"
      })
      |> Isee.Cameras.create_camera()

    camera
  end
end
