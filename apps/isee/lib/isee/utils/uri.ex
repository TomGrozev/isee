defmodule Isee.Utils.URI do
  @moduledoc """
  Implements Ecto.Type behavior for storing URIs
  """

  use Ecto.Type

  @doc """
  Defines what internal database type is used.
  """
  def type, do: :string

  @doc """
  Cast to a URI type
  """
  def cast(value) do
    if valid_url?(value) do
      load(value)
    else
      {:error, message: "invalid url format"}
    end
  end

  @doc """
  Loads the URI as string from the database and coverts to a URI type.
  """
  def load(value), do: URI.new(value)

  @doc """
  Uses itself in an embed
  """
  def embed_as(_), do: :self

  @doc """
  Checks if the two URIs are equal
  """
  def equal?(uri1, uri2) when not is_nil(uri1) and not is_nil(uri2), do: Map.equal?(uri1, uri2)
  def equal?(_, _), do: false

  @doc """
  Receives URI and converts to string. In case URI is not valid it returns an error.
  """
  def dump(%URI{} = value) do
    uri = URI.to_string(value)

    {:ok, uri}
  end

  def dump(_), do: :error

  defp valid_url?(url) do
    String.match?(
      url,
      ~r"https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)"
    )
  end
end
