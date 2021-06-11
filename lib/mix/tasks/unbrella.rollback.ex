defmodule Mix.Tasks.Unbrella.Rollback do
  use Mix.Task
  import Mix.Ecto
  import Mix.EctoSQL
  import Unbrella.Utils

  @shortdoc "Rolls back the repository migrations"
  @recursive true

  @aliases [
    r: :repo,
    n: :step
  ]

  @switches [
    all: :boolean,
    step: :integer,
    to: :integer,
    quiet: :boolean,
    prefix: :string,
    pool_size: :integer,
    log_sql: :boolean,
    repo: [:keep, :string],
    no_compile: :boolean,
    no_deps_check: :boolean,
    migrations_path: :keep
  ]

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

    * `--step`, `-n` - revert n number of applied migrations

    * `--to` - revert all migrations down to and including version

    * `--quiet` - do not log migration commands

    * `--prefix` - the prefix to run migrations on

    * `--pool-size` - the pool size if the repository is started only for the task (defaults to 2)

    * `--log-sql` - log the raw sql migrations are running

    * `--no-compile` - does not compile applications before rolling back

    * `--no-deps-check` - does not check dependencies before rolling back

    * `--migrations-path` - the path to load the migrations from, defaults to
      `"priv/repo/migrations"`. This option may be given multiple times in which case the migrations
      are loaded from all the given directories and sorted as if they were all in the same one.

      Note, if you have migrations paths e.g. `a/` and `b/`, and run
      `mix ecto.rollback --migrations-path a/`, only the latest migrations from `a/` will be
      rolled back (even if `b/` contains the overall latest migrations.)

  """

  @impl true
  def run(args, migrator \\ &Ecto.Migrator.run/4) do
    repos = parse_repo(args)
    {opts, _} = OptionParser.parse! args, strict: @switches, aliases: @aliases

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :step, 1)

    opts =
      if opts[:quiet],
        do: Keyword.merge(opts, [log: false, log_sql: false]),
        else: opts

    # Start ecto_sql explicitly before as we don't need
    # to restart those apps if migrated.
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    for repo <- repos do
      ensure_repo(repo, args)
      ensure_migrations_paths(repo, opts)
      paths = get_migrations(repo)
      pool = repo.config[:pool]

      fun =
        if Code.ensure_loaded?(pool) and function_exported?(pool, :unboxed_run, 2) do
          &pool.unboxed_run(&1, fn -> migrator.(&1, paths, :down, opts) end)
        else
          &migrator.(&1, paths, :down, opts)
        end

      case Ecto.Migrator.with_repo(repo, fun, [mode: :temporary] ++ opts) do
        {:ok, _migrated, _apps} -> :ok
        {:error, error} -> Mix.raise "Could not start repo #{inspect repo}, error: #{inspect error}"
      end
    end

    :ok
  end
end