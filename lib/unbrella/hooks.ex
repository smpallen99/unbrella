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

      Enum.each(Unbrella.modules(), fn module ->
        match?({:module, ^module}, Code.ensure_compiled(module))
      end)
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
      Module.put_attribute(__MODULE__, :defhooks, {unquote(name), unquote(arity)})
      Module.put_attribute(__MODULE__, :docs, {unquote(name), unquote(opts)[:doc]})
    end
  end

  @doc """
  Create or add hook function function.

  Create a hook function in the current module.

  ## Examples

      # create
      add_hook :preload_user, [:user, :preload] do
        Repo.preload user, [:extension | preload]
      end

      # add to existing
      add_hook :hook_function, MyHandler, :hook_handler
  """
  defmacro add_hook(name, args, do: block) do
    contents = Macro.escape(quote(do: unquote(block)), unquote: true)

    quote bind_quoted: [name: name, args: args, contents: contents] do
      Module.put_attribute(__MODULE__, :hooks, {name, {__MODULE__, name}})
      args = Enum.map(args, &Macro.var(&1, nil))

      def unquote(name)(unquote_splicing(args)) do
        unquote(contents)
      end
    end
  end

  defmacro add_hook(hook, module, name) do
    quote do
      Module.put_attribute(__MODULE__, :hooks, {unquote(hook), {unquote(module), unquote(name)}})
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

  @doc false
  defmacro __before_compile__(env) do
    hooks = Unbrella.hooks()
    definitions = Module.get_attribute(env.module, :defhooks)
    docs = Module.get_attribute(env.module, :docs)

    functions =
      for {hook, arity} <- definitions do
        hook_function(hook, arity, hooks[hook] || [], docs[hook])
      end

    quote do
      def defhooks, do: unquote(Macro.escape(definitions))
      def hook_list, do: unquote(Macro.escape(hooks))
      unquote_splicing(functions)
    end
  end

  defp hook_function(hook, 0, plugins, doc) do
    documentation = if doc, do: quote(do: @doc(unquote(doc)))

    quote do
      unquote(documentation)

      def unquote(hook)() do
        Enum.reduce_while(unquote(Macro.escape(plugins)), :ok, fn {module, fun}, _acc ->
          case apply(module, fun, []) do
            {:halt, _} = result -> result
            {:cont, _} = result -> result
            :halt -> {:halt, :abort}
            :cont -> {:cont, :ok}
            other -> {:cont, other}
          end
        end)
      end
    end
  end

  defp hook_function(hook, arity, plugins, doc) do
    args = for num <- 1..arity, do: Macro.var(String.to_atom("arg_#{num}"), Elixir)
    [head | tail] = args
    documentation = if doc, do: quote(do: @doc(unquote(doc)))

    quote do
      unquote(documentation)

      def unquote(hook)(unquote_splicing(args)) do
        Enum.reduce_while(unquote(Macro.escape(plugins)), unquote(head), fn {module, fun}, acc ->
          case apply(module, fun, [acc, unquote_splicing(tail)]) do
            {:halt, _} = result -> result
            {:cont, _} = result -> result
            other -> {:cont, other}
          end
        end)
      end
    end
  end

  @doc false
  defmacro __add_hooks_compile__(_) do
    quote unquote: false do
      def hooks, do: @hooks
    end
  end
end
