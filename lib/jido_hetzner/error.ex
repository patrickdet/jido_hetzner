defmodule JidoHetzner.Error do
  @moduledoc """
  Structured errors for Hetzner Cloud operations.

  Wraps `Jido.Shell.Error.command/2` with Hetzner-specific error codes.
  """

  alias Jido.Shell.Error

  @doc "Create an API-level error."
  @spec api(atom(), map()) :: Error.t()
  def api(code, ctx \\ %{}) do
    Error.command(:"hetzner_api_#{code}", ctx)
  end

  @doc "Create a provision-level error."
  @spec provision(atom(), map()) :: Error.t()
  def provision(code, ctx \\ %{}) do
    Error.command(:"hetzner_provision_#{code}", ctx)
  end

  @doc "Create a teardown-level error."
  @spec teardown(atom(), map()) :: Error.t()
  def teardown(code, ctx \\ %{}) do
    Error.command(:"hetzner_teardown_#{code}", ctx)
  end
end
