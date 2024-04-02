defmodule Isee.CamerasTest do
  use Isee.DataCase

  alias Isee.Cameras

  describe "cameras" do
    alias Isee.Cameras.Camera

    import Isee.CamerasFixtures

    @invalid_attrs %{latitude: nil, longitude: nil, name: nil, url: nil}

    test "list_cameras/0 returns all cameras" do
      camera = camera_fixture()
      assert Cameras.list_cameras() == [camera]
    end

    test "get_camera!/1 returns the camera with given id" do
      camera = camera_fixture()
      assert Cameras.get_camera!(camera.id) == camera
    end

    test "create_camera/1 with valid data creates a camera" do
      valid_attrs = %{
        latitude: "some latitude",
        longitude: "some longitude",
        name: "some name",
        url: "some url"
      }

      assert {:ok, %Camera{} = camera} = Cameras.create_camera(valid_attrs)
      assert camera.latitude == "some latitude"
      assert camera.longitude == "some longitude"
      assert camera.name == "some name"
      assert camera.url == "some url"
    end

    test "create_camera/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Cameras.create_camera(@invalid_attrs)
    end

    test "update_camera/2 with valid data updates the camera" do
      camera = camera_fixture()

      update_attrs = %{
        latitude: "some updated latitude",
        longitude: "some updated longitude",
        name: "some updated name",
        url: "some updated url"
      }

      assert {:ok, %Camera{} = camera} = Cameras.update_camera(camera, update_attrs)
      assert camera.latitude == "some updated latitude"
      assert camera.longitude == "some updated longitude"
      assert camera.name == "some updated name"
      assert camera.url == "some updated url"
    end

    test "update_camera/2 with invalid data returns error changeset" do
      camera = camera_fixture()
      assert {:error, %Ecto.Changeset{}} = Cameras.update_camera(camera, @invalid_attrs)
      assert camera == Cameras.get_camera!(camera.id)
    end

    test "delete_camera/1 deletes the camera" do
      camera = camera_fixture()
      assert {:ok, %Camera{}} = Cameras.delete_camera(camera)
      assert_raise Ecto.NoResultsError, fn -> Cameras.get_camera!(camera.id) end
    end

    test "change_camera/1 returns a camera changeset" do
      camera = camera_fixture()
      assert %Ecto.Changeset{} = Cameras.change_camera(camera)
    end
  end
end
