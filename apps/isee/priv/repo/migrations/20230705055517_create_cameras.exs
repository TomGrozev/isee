defmodule Isee.Repo.Migrations.CreateCameras do
  use ArangoXEcto.Migration

  def change do
    create table(:cameras) do
      add(:url, :string)
      add(:location, :map)
      add(:name, :string)

      timestamps()
    end

    create(index(:cameras, [:location], type: :geo, geoJson: true))
  end
end
