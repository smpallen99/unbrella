defmodule Unbrella.Plugin.Schema do
  @moduledoc """
  Macros to extend a schema from a plugin.
  """

  @doc false
  defmacro __using__(schema) do
    quote do
      import unquote(__MODULE__)
      use Ecto.Schema, except: [field: 3]
      import Ecto.Changeset

      Module.register_attribute(__MODULE__, :schema_fields, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :schema_module, persist: true)

      def __target_schema__ do
        unquote(schema)
      end
    end
  end

  @doc """
  Add fields to a main apps schmea.
  """
  defmacro extend_schema(mod, do: contents) do
    quote do
      module = unquote(mod)
      Module.put_attribute(__MODULE__, :schema_module, module)
      unquote(contents)
      # IO.puts "schema_fields: #{inspect @schema_fields}"
      # IO.puts "schema_fields2: #{inspect hd(@schema_fields)}"
      def schema_fields do
        {@schema_module, @schema_fields}
      end
    end
  end

  Enum.map(~w(field has_many belongs_to has_one many_to_many embeds_one embeds_many)a, fn field ->
    defmacro unquote(field)(name, type, opts \\ []) do
      field = unquote(field)

      quote bind_quoted: [name: name, type: type, opts: opts, field: field] do
        Module.put_attribute(__MODULE__, :schema_fields, {field, name, type, opts})
      end
    end
  end)
end
