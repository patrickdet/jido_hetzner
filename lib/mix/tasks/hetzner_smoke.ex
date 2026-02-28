defmodule Mix.Tasks.HetznerSmoke do
  @moduledoc """
  Manual smoke test against real Hetzner Cloud.

  Provisions a VM, SSHs in, runs a command, tears it all down.

      HETZNER_API_TOKEN=hc_... mix hetzner_smoke

  Options:
    --server-type cx22       (default: cx22)
    --image ubuntu-24.04     (default: ubuntu-24.04)
    --location fsn1          (default: fsn1)
    --keep                   Skip teardown (leave VM running for debugging)
  """

  use Mix.Task

  @shortdoc "Smoke test: provision Hetzner VM, SSH in, teardown"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [server_type: :string, image: :string, location: :string, keep: :boolean]
      )

    token = System.get_env("HETZNER_API_TOKEN")

    unless token do
      Mix.shell().error("Missing HETZNER_API_TOKEN environment variable")
      System.halt(1)
    end

    workspace_id = "smoke-#{:erlang.unique_integer([:positive])}"

    config = %{
      api_token: token,
      server_type: opts[:server_type] || "cpx11",
      image: opts[:image] || "ubuntu-24.04",
      location: opts[:location] || "hel1"
    }

    log("Starting smoke test: workspace=#{workspace_id}")
    log("Config: server_type=#{config.server_type} image=#{config.image} location=#{config.location}")

    log("\n--- PROVISION ---")
    t0 = System.monotonic_time(:second)

    case JidoHetzner.Environment.provision(workspace_id, config, []) do
      {:ok, result} ->
        elapsed = System.monotonic_time(:second) - t0
        log("Provisioned in #{elapsed}s")
        log("  server_id:  #{result.server_id}")
        log("  ip:         #{result.ip_address}")
        log("  session_id: #{result.session_id}")
        log("  workspace:  #{result.workspace_dir}")
        log("  ssh_key_id: #{result.ssh_key_id}")

        log("\n--- EXECUTE COMMANDS ---")
        run_test_commands(result.session_id)

        if opts[:keep] do
          log("\n--- KEEPING VM (--keep) ---")
          log("  SSH: ssh root@#{result.ip_address}")
          log("  Teardown manually later or re-run without --keep")
        else
          log("\n--- TEARDOWN ---")
          t1 = System.monotonic_time(:second)

          teardown_result =
            JidoHetzner.Environment.teardown(result.session_id,
              config: config,
              server_id: result.server_id,
              ssh_key_id: result.ssh_key_id,
              ssh_key_cleanup: result.ssh_key_cleanup
            )

          elapsed2 = System.monotonic_time(:second) - t1
          log("Teardown in #{elapsed2}s")
          log("  verified:  #{teardown_result.teardown_verified}")
          log("  attempts:  #{teardown_result.teardown_attempts}")
          log("  warnings:  #{inspect(teardown_result.warnings)}")
        end

        log("\nSMOKE TEST PASSED")

      {:error, error} ->
        elapsed = System.monotonic_time(:second) - t0
        log("PROVISION FAILED after #{elapsed}s")
        log("  error: #{inspect(error)}")
        log("\nSMOKE TEST FAILED")
        System.halt(1)
    end
  end

  defp run_test_commands(session_id) do
    agent_mod = Jido.Shell.Agent

    commands = [
      {"hostname", "Check hostname"},
      {"uname -a", "Check kernel"},
      {"whoami", "Check user"},
      {"cat /etc/os-release | head -3", "Check OS"},
      {"df -h /", "Check disk"},
      {"free -m", "Check memory"}
    ]

    for {cmd, label} <- commands do
      case Jido.Shell.Exec.run(agent_mod, session_id, cmd, timeout: 15_000) do
        {:ok, output} ->
          log("  [OK] #{label}: #{String.trim(output)}")

        {:error, reason} ->
          log("  [FAIL] #{label}: #{inspect(reason)}")
      end
    end
  end

  defp log(msg), do: Mix.shell().info(msg)
end
