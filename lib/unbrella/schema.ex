defmodule Unbrella.Schema do
  @moduledoc """
  Support extending schmea from plugins.

  Use the moduile in your main project's schmea file to all plugins 
  to extend the schmea and add changeset callbacks. By using this module,
  you are overriding the `Ecto.Schema.schema` macros. This allows us 
  to append the plugin's schema extensions during compile time.'

  ## Usage
  
      # lib/my_app/accounts/account.ex
      defmodule MyApp.Accounts.Account do
        use Unbrella.Schema
        import Ecto.Changeset

        schema "accounts_accounts" do
          belongs_to :user, User
          timestamps(type: :utc_datetime)
        end

        def changeset(%Account{} = account, attrs \\ %{}) do
          account
          |> cast(attrs, [:user_id])
          |> validate_required([:user_id])
          |> plugin_changesets(attrs, Account)
        end
      end
  
  Now you can extend the account schema in your plugin.

      # plugins/plugin1/lib/plugin1/accounts/account.ex
      defmodule Plugin1.Accounts.Account do
        use Unbrella.Plugin.Schema, MyApp.Accounts.Account
        import Ecto.Query

        extend_schema MyApp.Accounts.Account do
          field :language, :string, default: "on"
          field :notification_enabled, :boolean, default: true
          many_to_many :notifications, MyApp.Notification, join_through: MyApp.AccountNotification
        end

        def changeset(changeset, params \\ %{}) do
          changeset
          |> cast(params, [:language, :notification_enabled])
          |> validate_required([:language, :notification_enabled])
        end
      end
  """

  import Unbrella.Utils

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      use Ecto.Schema
      import Ecto.Schema, except: [schema: 1, schema: 2]
    end
  end

  @doc """
  Macro to append all the plugins schema extensions.

  Appends each plugins' `extend_schema` fields to the main schema.

  To use this macro, simply replace the `use Ecto.Schema` with 
  `use Unbrella.Schema`. That will remove the normally imported 
  `Ecto.Schema.schema` macro.
  """
  defmacro schema(table, do: block) do
    calling_mod = __CALLER__.module

    modules =
      calling_mod
      |> get_modules
      |> List.flatten
      |> Macro.escape

    quote do
      Ecto.Schema.schema unquote(table) do
        unquote(block)
        require Ecto.Schema
        Enum.map unquote(modules), fn {fun, name, mod, opts} = abc ->
          case fun do
            :has_many ->
              Ecto.Schema.has_many(name, mod, opts)
            :field ->
              Ecto.Schema.field(name, mod, opts)
            :has_one ->
              Ecto.Schema.has_one(name, mod, opts)
            :belongs_to ->
              Ecto.Schema.belongs_to(name, mod, opts)
            :many_to_many ->
              Ecto.Schema.many_to_many(name, mod, opts)
            :embeds_many ->
              Ecto.Schema.embeds_many(name, mod, opts)
            :embeds_one ->
              Ecto.Schema.embeds_one(name, mod, opts)
          end
        end
      end
    end
  end

  @doc """
  Call each plugins' `changeset/2` function.

  ## Usage

      # lib/my_app/accounts/account.ex
      defmodule MyApp.Accounts.Account do
        use Unbrella.Schema
        import Ecto.Changeset
        # ...
        def changeset(%Account{} = account, attrs \\ %{}) do
          account
          |> cast(attrs, [:user_id])
          |> validate_required([:user_id])
          |> plugin_changesets(attrs, Account)
        end
      end
  """
  defmacro plugin_changesets(changeset, attrs, schema) do
    changesets =
      Enum.reduce(get_schemas(), [], fn mod, acc ->
        if function_exported?(mod, :changeset, 2) do
          [mod | acc]
        else
          acc
        end
      end)

    quote bind_quoted: [changeset: changeset, attrs: attrs, schema: schema, changesets: changesets] do
      Enum.reduce changesets, changeset, fn mod, acc ->
        if mod.__target_schema__() == schema do
          apply mod, :changeset, [acc, attrs]
        else
          acc
        end
      end
    end

  end


end
