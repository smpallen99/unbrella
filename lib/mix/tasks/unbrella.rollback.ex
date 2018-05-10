defmodule Mix.Tasks.Unbrella.Rollback do
  use Mix.Task
  import Mix.Ecto
  import Unbrella.Utils

  @shortdoc "Rolls back the repository migrations"
  @recursive true

  @moduledoc """
  Reverts applied migrations in the given repository.

  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.

  By default, migrations are expected at "priv/YOUR_REPO/migrations"
  directory of the current application but it can be configured
  by specifying the `:priv` key under the repository configuration.

  Runs the latest applied migration by default. To roll back to
  to a version number, supply `--to version_number`.
  To roll back a specific number of times, use `--step n`.
  To undo all applied migrations, provide `--all`.

  If the repository has not been started yet, one will be
  started outside our application supervision tree and shutdown
  afterwards.

  ## Examples

      mix unbrella.rollback
      mix unbrella.rollback -r Custom.Repo

      mix unbrella.rollback -n 3
      mix unbrella.rollback --step 3

      mix unbrella.rollback -v 20080906120000
      mix unbrella.rollback --to 20080906120000

  ## Command line options

    * `-r`, `--repo` - the repo to rollback
    * `--all` - revert all applied migrations
    * `--step` / `-n` - revert n number of applied migrations
    * `--to` / `-v` - revert all migrations down to and including version
    * `--quiet` - do not log migration commands
    * `--prefix` - the prefix to run migrations on
    * `--pool-size` - the pool size if the repository is started only for the task (defaults to 1)

  """

  @doc false
  def run(args, migrator \\ &Ecto.Migrator.run/4) do
    repos = parse_repo(args)

    {opts, _, _} = OptionParser.parse args,
      switches: [all: :boolean, step: :integer, to: :integer, start: :boolean,
                 quiet: :boolean, prefix: :string, pool_size: :integer],
      aliases: [n: :step, v: :to]

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :step, 1)

    opts =
      if opts[:quiet],
        do: Keyword.put(opts, :log, false),
        else: opts

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      ensure_migrations_path(repo)
      {:ok, pid, apps} = ensure_started(repo, opts)

      sandbox? = repo.config[:pool] == Ecto.Adapters.SQL.Sandbox

      # If the pool is Ecto.Adapters.SQL.Sandbox,
      # let's make sure we get a connection outside of a sandbox.
      if sandbox? do
        Ecto.Adapters.SQL.Sandbox.checkin(repo)
        Ecto.Adapters.SQL.Sandbox.checkout(repo, sandbox: false)
      end

      migrated = try_migrating(repo, migrator, sandbox?, opts)

      pid && repo.stop(pid)
      restart_apps_if_migrated(apps, migrated)
    end
  end

  defp try_migrating(repo, migrator, sandbox?, opts) do
    try do
      Enum.reduce([migrations_path(repo) | get_migration_paths()], [], fn path, acc ->
        [migrator.(repo, path, :down, opts) | acc]
      end)
    after
      sandbox? && Ecto.Adapters.SQL.Sandbox.checkin(repo)
    end
  end
end