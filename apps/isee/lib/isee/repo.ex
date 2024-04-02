defmodule Isee.Repo do
  use Ecto.Repo,
    otp_app: :isee,
    adapter: ArangoXEcto.Adapter
end
