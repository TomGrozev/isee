defmodule Isee.Utils.Helpers do
  @moduledoc """
  Helper functions that don't belong anywhere else
  """

  @doc """
  Resolves the IP address for the hostname provided
  """
  @spec hostname_to_ip(String.t()) :: {:ok, tuple()} | {:error, any()}
  def hostname_to_ip(host) do
    case :inet_res.nslookup(String.to_charlist(host), :in, :a) do
      {:ok, {:dns_rec, _, _, [{:dns_rr, _, _, _, _, _, ip, _, _, _}], _, _}} ->
        {:ok,
         ip
         |> :inet.ntoa()
         |> to_string()}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, "error resolving the hostname"}
    end
  end
end
