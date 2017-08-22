defmodule Unbrella.Hooks do
  @moduledoc """
  API for creating hook functions.

  """
  @doc false
  defmacro __using__(:defhooks) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :defhooks, persist: true, accumulate: true)
      Module.register_attribute(__MODULE__, :docs, persist: true, accumulate: true)

      Enum.each Unbrella.modules, &Code.ensure_compiled/1

    end
  end

  @doc false
  defmacro __using__(:add_hooks) do
    quote do

      @before_compile {unquote(__MODULE__), :__add_hooks_compile__}

      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :hooks, persist: true, accumulate: true)
    end
  end

  @doc """
  Add a hook.

  ## Examples

      defmodule UcxUcc.Hooks do
        use UcxUcc.Hooks.Api

        add_hook :post_fetch_user, 1, doc; \"""
          Called with a list of users after fetched from the database.

          Can be used to add post processing or filtering to the list.
          \"""
  """
  defmacro defhook(name, arity, opts \\ []) do
    quote do
      Module.put_attribute __MODULE__, :defhooks, {unquote(name), unquote(arity)}
      Module.put_attribute __MODULE__, :docs, {unquote(name), unquote(opts)[:doc]}
    end
  end

  @doc """
  Add an existing module hook.

  Given an existing hook function, add it to the hooks list.

  ## Examples

      add_hook MyHander, :hook_function
  """
  defmacro add_hook(module, name) do
    quote do
      Module.put_attribute(__MODULE__, :hooks, {unquote(name), {unquote(module), unquote(name)}})
    end
  end

  @doc """
  Create a hook function.

  Create a hook function in the current module.

  ## Examples

      add_hook :preload_user, [:user, :preload] do
        Repo.preload user, [:extension | preload]
      end
  """
  defmacro add_hook(name, args, do: block) do
    contents =
      quote do
        unquote(block)
      end
    contents = Macro.escape contents, unquote: true
    quote bind_quoted: [name: name, args: args, contents: contents] do
      Module.put_attribute(__MODULE__, :hooks, {name, {__MODULE__, name}})
      args = Enum.map args, &Macro.var(&1, nil)
      def unquote(name)(unquote_splicing(args)) do
        unquote(contents)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote unquote: false do

      @hook_list Unbrella.hooks
      IO.inspect Unbrella.hooks, label: "unbrella.hooks"

      def defhooks, do: @defhooks
      def hook_list, do: @hook_list

      Enum.each @defhooks, fn {hook, arity} ->
        @plugins  @hook_list[hook]

        args = for num <- 1..arity,
          do: Macro.var(String.to_atom("arg_#{num}"), Elixir)

        if doc = @docs[hook] do
          @doc doc
        end
        def unquote(hook)(unquote_splicing(args)) do
          [h | t] = unquote(args)
          Enum.reduce(@plugins, h, fn {module, fun}, acc ->
            apply module, fun, [acc | t]
          end)
        end
      end
    end
  end

  @doc false
  defmacro __add_hooks_compile__(_) do
    quote unquote: false do
      def hooks do
        @hooks
      end
    end
  end

end
