defmodule JidoHetznerTest do
  use ExUnit.Case

  test "module compiles and exports public API" do
    assert {:module, JidoHetzner} = Code.ensure_loaded(JidoHetzner)
    assert function_exported?(JidoHetzner, :provision, 3)
    assert function_exported?(JidoHetzner, :teardown, 2)
    assert function_exported?(JidoHetzner, :status, 2)
  end

  test "error module creates structured errors" do
    error = JidoHetzner.Error.api(:unauthorized, %{})
    assert %Jido.Shell.Error{code: {:command, :hetzner_api_unauthorized}} = error

    error = JidoHetzner.Error.provision(:timeout, %{})
    assert %Jido.Shell.Error{code: {:command, :hetzner_provision_timeout}} = error

    error = JidoHetzner.Error.teardown(:failed, %{})
    assert %Jido.Shell.Error{code: {:command, :hetzner_teardown_failed}} = error
  end
end
